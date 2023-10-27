// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "src/WethGateWay.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";
import "../lib/solmate/src/tokens/WETH.sol";
import "../lib/solmate/src/utils/SafeTransferLib.sol";


    //////////////////////////// INTERFACES \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
interface IAToken {
    function mintAToken(address to, uint256 amount) external;

    function burnAToken(address account, uint256 amount) external;
}

interface IDebToken {
    function mintDebToken(address to, uint256 amount) external;

    function burnDebToken(address account, uint256 amount) external;
}

contract LendingPool {

    //////////////////////////// EVENTS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    event Deposited(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount, uint256 rewards);

    event Borrowed(address indexed user, uint256 amount);

    event Repaied(address indexed user, uint256 amount, uint256 interest);

    //////////////////////////// ERRORS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

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
    error OverFlow();

    //////////////////////////// STORAGE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

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
    IERC20 public immutable iercWeth;

    ////////////////////////// CONSTRUCTOR \\\\\\\\\\\\\\\\\\\\\\\\\\\\

    constructor(
        address _atoken,
        address _debtoken,
        address payable _tokenWeth,
        address payable _gateway
    ) {
        atoken = IAToken(_atoken);
        debtoken = IDebToken(_debtoken);
        tokenWeth = WETH(_tokenWeth);
        iercWeth = IERC20(_tokenWeth);
        gateway = WethGateWay(_gateway);
    }

    ///////////////////// USER-FACING FUNCTIONS \\\\\\\\\\\\\\\\\\\\\\\\

    /*
     * @notice The user deposits an amount of wETH and receives the same amount of ATokens
     * @param address The user's address.,
     * @param amount The amount to be deposited.
    */
    function deposit(address user, uint128 amount) external {
        Data storage data = supplies[user];

        if (amount == 0) revert AmountCannotBe0();
        if (data.state != State.INITIAL) revert AlreadyHaveADeposit();
        if (user == address(0)) revert addressCannotBe0x0();

        data.supplier = user;
        data.amountDeposit = amount;
        data.timeSupply;
        data.state = State.SUPPLIER;

        unchecked {
            balanceSupply += amount;
            totalSupplies++;
        }

        _transferFrom(ERC20(tokenWeth), msg.sender, address(this), amount);

        IAToken(address(atoken)).mintAToken(user, amount);

        emit Deposited(user, amount);
    }

    /*
     * @notice Withdraws all or part of the deposited weth tokens, 
     * burn the same amount from the user.
     * @param address The user's address.,
     * @param amount The amount to be withdrwed.
    */
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

        _transfer(ERC20(tokenWeth), msg.sender, amountToWithdraw);
        IAToken(address(atoken)).burnAToken(user, amount);

        emit Withdrawn(user, amount, rewards);
    }

    /*
     * @notice Borrows a maximum of 40% of the deposited amount,
     * the users recieves the same amount of DebTokens.
     * @param address The user's address.,
     * @param amount The amount to be borrowed.
    */
    function borrow(address user, uint128 amount) external {
        Data storage data = supplies[user];

        if (amount == 0) revert AmountCannotBe0();
        if (user == address(0)) revert addressCannotBe0x0();
        if (data.state != State.SUPPLIER)
            revert ThereIsNoDeposit_AlreadyRequestedALoan();

        uint256 maxAmountToBorrow = _maxAmountLoan(user);
        if (amount > maxAmountToBorrow) revert AmountExceeded();

        data.amountBorrowed = amount;
        data.timeBorrow;
        data.state = State.BORROWER;

        unchecked {
            balanceBorrow += amount;
            totalBorrows++;
        }

        _transfer(ERC20(tokenWeth), msg.sender, amount);
        IDebToken(address(debtoken)).mintDebToken(user, amount);

        emit Borrowed(user, amount);
    }

    /*
     * @notice Pays all or part of the loan, and burn Dbebtoken's amount from user.
     * @param address The user's address.,
     * @param amount The amount to be repaied.
    */
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

        _transferFrom(
            ERC20(tokenWeth),
            msg.sender,
            address(this),
            amountToRepay
        );
        IDebToken(address(debtoken)).burnDebToken(user, amount);

        emit Repaied(user, amount, interest);
    }

    //////////////////////////// CALCULTATION FUNCTIONS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    /*
     * @notice Calculate profits with a fixed annual percentage.
    */
    function calculateRewards(
        uint256 amount,
        address user
    ) public view returns (uint256) {
        Data memory data = supplies[user];

        uint256 timeSupply = data.timeSupply;
        uint256 percent = (((timeSupply * 10) * 1e18) / 365 days) / 100;
        return (amount * percent) / 1e18;
    }
    
    /*
     * @notice Calculates interest with a fixed annual percentage.
    */
    function calculateInterest(
        uint256 amount,
        address user
    ) public view returns (uint256) {
        Data memory data = supplies[user];

        uint256 timeSupply = data.timeBorrow;
        uint256 percent = (((timeSupply * 10) * 1e18) / 365 days) / 100;
        return (amount * percent) / 1e18;
    }

    //////////////////////////// INTERNAL FUNCTIONS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

    /*
     * @dev Calculate 40% of the amount deposited to be able to borrow..
    */
    function _maxAmountLoan(address user) internal view returns (uint256) {
        uint256 amount = supplies[user].amountDeposit;
        return (amount * 40) / 100;
    }

    /*
     * @dev Transfer the tokens with the SafeTransferLib librasry.
    */
    function _transfer(
        ERC20 asset,
        address to,
        uint256 amount
    ) internal {
        SafeTransferLib.safeTransfer(ERC20(asset), to, amount);
    }
    
    /*
     * @dev Transfer the tokens with the SafeTransferLib librasry.
    */
    function _transferFrom(
        ERC20 asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeTransferLib.safeTransferFrom(ERC20(asset), from, to, amount);
    }

    
}
