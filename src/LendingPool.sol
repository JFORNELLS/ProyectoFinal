// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "src/WethGateWay.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";
import "../lib/solmate/src/tokens/WETH.sol";

interface IAToken {
    function mintAToken(address to, uint256 amount) external;

    function burnAToken(address account, uint256 amount) external;
}

interface IDebToken {
    function mintDebToken(address to, uint256 amount) external;

    function burnDebToken(address account, uint256 amount) external;
}

contract LendingPool {
    event Deposited(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount, uint256 rewards);

    event Borrowed(address indexed user, uint256 amount);

    event Repaied(address indexed user, uint256 amount, uint256 interest);

    error AmountCannotBe0();
    error AlreadyHaveADeposit();
    error MustRepayTheLoan__ThereIsNoDeposit();
    error ThereIsNoDeposit_AlreadyRequestedALoan();
    error MustRepayTheLoan();
    error AmountMustBeLess();
    error InsuficientWeth();
    error AlreadyABorrow();
    error AmountExceeded();
    error HasNotALoan();
    error addressCannotBe0x0();
    error InsuficientAmountDeposit();
    error AmountExceedsDebt();

    enum State {
        INITIAL,
        SUPPLIER,
        BORROWER
    }

    struct Data {
        uint128 amountDeposit;
        uint128 amountBorrowed;
        uint48 timeSupply;
        uint48 timeBorrow;
        State state;
        address supplier;
    }
    mapping(address => Data) public supplies;

    uint256 public totalSupplies;
    uint256 public balanceSupply;
    uint256 public totalBorrows;
    uint256 public balanceBorrow;

    IAToken public immutable atoken;
    IDebToken public immutable debtoken;
    WETH public immutable tokenWeth;
    WethGateWay public immutable gateway;
    IERC20 public immutable iercAToken;
    IERC20 public immutable iercDebToken;
    IERC20 public immutable iercWeth;
    address private immutable owner;

    constructor(
        address _atoken,
        address _debtoken,
        address payable _tokenWeth,
        address payable _gateway,
        address _owner
    ) {
        atoken = IAToken(_atoken);
        debtoken = IDebToken(_debtoken);
        iercAToken = IERC20(_atoken);
        iercDebToken = IERC20(_debtoken);
        tokenWeth = WETH(_tokenWeth);
        iercWeth = IERC20(_tokenWeth);
        gateway = WethGateWay(_gateway);
        owner = _owner;
    }

    function deposit(address user, uint128 amount) external {
        Data storage data = supplies[user];

        if (amount == 0) revert AmountCannotBe0();
        if (data.state != State.INITIAL) revert AlreadyHaveADeposit();
        if (user == address(0)) revert addressCannotBe0x0();

        data.supplier = user;
        data.amountDeposit = amount;
        data.timeSupply = 182.5 days; //cantitat per fer proves
        data.state = State.SUPPLIER;

        unchecked {
            balanceSupply += amount;
            totalSupplies++;
        }

        iercWeth.transferFrom(msg.sender, address(this), amount);

        IAToken(address(atoken)).mintAToken(user, amount);

        emit Deposited(user, amount);
    }

    function withdraw(address user, uint128 amount) external {
        Data storage data = supplies[user];

        if (amount == 0) revert AmountCannotBe0();
        if (user == address(0)) revert addressCannotBe0x0();
        if (data.state != State.SUPPLIER)
            revert MustRepayTheLoan__ThereIsNoDeposit();
        if (amount > data.amountDeposit) revert AmountMustBeLess();

        uint256 rewards = calculateRewards(amount, user);
        uint256 amountToWithdraw = amount + rewards;

        unchecked {
            data.amountDeposit -= amount;
            if (data.amountDeposit == 0) {
                data.state = State.INITIAL;
            }
            balanceSupply -= amount;
            totalSupplies--;
        }

        iercAToken.transferFrom(msg.sender, address(this), amount);

        iercWeth.transfer(msg.sender, amountToWithdraw);

        IAToken(address(atoken)).burnAToken(address(this), amount);

        emit Withdrawn(user, amount, rewards);
    }

    function borrow(address user, uint128 amount) external {
        Data storage data = supplies[user];

        if (amount == 0) revert AmountCannotBe0();
        if (user == address(0)) revert addressCannotBe0x0();
        if (data.state != State.SUPPLIER)
            revert ThereIsNoDeposit_AlreadyRequestedALoan();

        uint256 maxAmountToBorrow = maxAmountLoan(user);
        if (amount > maxAmountToBorrow) revert AmountExceeded();

        data.amountBorrowed = amount;
        data.timeBorrow = 365 days; //cantitat per fer proves
        data.state = State.BORROWER;

        unchecked {
            balanceBorrow += amount;
            totalBorrows++;
        }

        iercWeth.transfer(msg.sender, amount);

        IDebToken(address(debtoken)).mintDebToken(user, amount);

        emit Borrowed(user, amount);
    }

    function repay(address user, uint128 amount) external {
        Data storage data = supplies[user];

        if (amount == 0) revert AmountCannotBe0();
        if (user == address(0)) revert addressCannotBe0x0();
        if (data.state != State.BORROWER) revert HasNotALoan();
        if (amount > data.amountBorrowed) revert AmountExceedsDebt();

        uint256 interest = calculateInterest(amount, user);
        uint256 amountToRepay = amount + interest;

        if (iercWeth.balanceOf(msg.sender) < amountToRepay)
            revert InsuficientWeth();

        unchecked {
            data.amountBorrowed -= amount;
            if (data.amountBorrowed == 0) {
                data.state = State.SUPPLIER;
            }
            balanceBorrow -= amount;
            totalBorrows--;
        }

        iercWeth.transferFrom(msg.sender, address(this), amountToRepay);

        IDebToken(address(debtoken)).burnDebToken(msg.sender, amount);

        emit Repaied(user, amount, interest);
    }

    function calculateRewards(
        uint256 amount,
        address user
    ) public view returns (uint256) {
        Data memory data = supplies[user];

        uint256 timeSupply = data.timeSupply;
        uint256 percent = (((timeSupply * 10) * 1e18) / 365 days) / 100;
        return (amount * percent) / 1e18;
    }

    function calculateInterest(
        uint256 amount,
        address user
    ) public view returns (uint256) {
        Data memory data = supplies[user];

        uint256 timeSupply = data.timeBorrow;
        uint256 percent = (((timeSupply * 10) * 1e18) / 365 days) / 100;
        return (amount * percent) / 1e18;
    }

    function maxAmountLoan(address user) internal view returns (uint256) {
        uint256 amount = supplies[user].amountDeposit;
        return (amount * 40) / 100;
    }
}
