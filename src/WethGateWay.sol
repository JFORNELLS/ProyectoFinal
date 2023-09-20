// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "src/AToken.sol";
import "src/DebToken.sol";
import "../lib/solmate/src/tokens/WETH.sol";
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract WethGateWay {
    using SafeTransferLib for ERC20;

    IWETH public immutable iweth;
    WETH public immutable weth;
    AToken public immutable atoken;
    DebToken public immutable debtoken;
    LendingPool public immutable lend;
    IERC20 public immutable iercWeth;

    constructor(
        address _atoken,
        LendingPool _lend,
        address _iweth,
        address _debtoken
    ) {
        atoken = AToken(_atoken);
        lend = _lend;
        iweth = IWETH(_iweth);
        weth = WETH(payable(_iweth));
        iercWeth = IERC20(_iweth);
        debtoken = DebToken(_debtoken);
    }

    function depositETH() public payable {
        address user = msg.sender;

        iweth.deposit{value: msg.value}();
        approve(weth, address(lend), msg.value);
        lend.deposit(user, uint128(msg.value));
    }

    function withdrawETH(uint128 amount) public payable {
        address user = msg.sender;

        lend.withdraw(user, amount);
        uint256 amountToWithdraw = amount + lend.calculateRewards(amount, user);

        iweth.withdraw(amountToWithdraw);
        transferETH(msg.sender, amountToWithdraw);
    }

    function borrowETH(uint128 amount) public payable {
        address user = msg.sender;
        lend.borrow(user, amount);
        iweth.withdraw(amount);
        transferETH(msg.sender, amount);
    }

    function repayETH(uint128 amount) public payable {
        address user = msg.sender;

        uint256 interest = lend.calculateInterest(amount, user);
        uint256 amountToRepay = amount + interest;

        iweth.deposit{value: msg.value}();
        approve(weth, address(lend), amountToRepay);
        lend.repay(user, amount);
    }

    function transferETH(address to, uint256 amount) public returns (bool) {
        SafeTransferLib.safeTransferETH(to, amount);
        return true;
    }

    function approve(
        ERC20 token,
        address to,
        uint256 amount
    ) public returns (bool) {
        SafeTransferLib.safeApprove(ERC20(token), to, amount);
        return true;
    }

    receive() external payable {}
}
