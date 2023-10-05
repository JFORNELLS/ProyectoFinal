//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/WethGateWay.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";
import "../src/DebToken.sol";
import "../src/AToken.sol";
import "../lib/solmate/src/tokens/WETH.sol";

contract WethGateWayTest is Test {
    event Deposited(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount, uint256 rewards);

    event Borrowed(address indexed user, uint256 amount);

    event Repaied(address indexed user, uint256 amount, uint256 interest);

    WETH public weth;
    IERC20 public iercWeth;
    IERC20 public iercAToken;
    IERC20 public iercDebToken;
    address public alice;
    AToken public atoken;
    DebToken public debtoken;
    LendingPool public lend;
    WethGateWay public gateway;
    address public owner;

    function setUp() public {
        debtoken = new DebToken(
            payable(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9)
        );
        atoken = new AToken(
            payable(0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9)
        );
        weth = new WETH();

        lend = new LendingPool(
            address(atoken),
            address(debtoken),
            payable(address(weth)),
            payable(address(gateway))
        );

        gateway = new WethGateWay(
            address(atoken),
            lend,
            address(weth),
            address(debtoken)
        );

        iercDebToken = IERC20(address(debtoken));
        iercAToken = IERC20(address(atoken));
        iercWeth = IERC20(address(weth));

        alice = makeAddr("alice");
        vm.deal(alice, 2 ** 148 wei);
        vm.deal(address(0), 2 ** 128 wei);
        vm.deal(address(this), 2 ** 128 - 1 wei);
        deal(address(weth), address(lend), 2 ** 200 wei);
        vm.deal(address(gateway), 3 ether);
    }

    function testFuzz_DepositETH(uint128 amount) public {
        vm.assume(amount > 0.1 ether);
        // Check that user is not tHE address 0.
        vm.startPrank(address(0));
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        gateway.depositETH{value: amount}();
        vm.stopPrank();

        vm.startPrank(alice);

        // If amount is 0 the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.depositETH{value: 0 ether}();

        // Save the value for checking after the deposit.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();
        uint256 balanceAlice = address(alice).balance;

        // Ckeck the deposit emit.
        vm.expectEmit();
        emit Deposited(address(alice), amount);

        // Deposit 2 ether.
        gateway.depositETH{value: amount}();

        // Check that alice has amount less.
        assertEq(address(alice).balance, balanceAlice - amount);

        // Check that alice has received 2 AToken.
        assertEq(iercAToken.balanceOf(address(alice)), amount);

        // Check that the variable is updated with the amount of the deposit.
        assertEq(lend.balanceSupply(), balSupply + amount);

        // Chech that the variable addsa + 1 after the deposit.
        assertEq(lend.totalSupplies(), supplies + 1);

        // If data.state in not equal to INITIAL, the function will revert.
        vm.expectRevert(LendingPool.AlreadyHaveADeposit.selector);
        gateway.depositETH{value: amount}();
    }

    function testFuzz_WithdrawETH(uint128 amount) public {
        // Give to LendinPool WETH tokeens from the WETH contract.
        gateway.depositETH{value: 2 ** 128 - 1 wei}();

        vm.assume(amount > 0.1 ether);

        // Save the value of amount2 -1 to verify the check (amount > data.amountDeposit).
        uint128 amount2 = amount - 1;

        // Check that user is not tHE address 0.
        vm.startPrank(address(0));
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        gateway.depositETH{value: amount2}();
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 balAkice = address(alice).balance;
        // Deposit ETH.
        gateway.depositETH{value: amount2}();

        // Check that alice has received 2 AToken.
        assertEq(iercAToken.balanceOf(address(alice)), amount2);

        // If amount to withdraw is 0 the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.withdrawETH(0 ether);

        // If the withdrawal amount is greater than the deposit amount,
        // the function will revert.
        vm.expectRevert(LendingPool.AmountMustBeLess.selector);
        gateway.withdrawETH(amount2 + 1);

        // Save the profit calculation to check alice's balance.
        uint256 rewards = lend.calculateRewards(amount2, address(alice));

        // Save the value for checking before the withdrawal.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();

        // Check the withdraw emit.
        vm.expectEmit();
        emit Withdrawn(address(alice), amount2, rewards);

        // Withdraw ETH.
        gateway.withdrawETH(amount2);

        //Check that alice has 0 AToken.
        assertEq(iercAToken.balanceOf(address(alice)), 0 ether);

        // Check that alice has 4 ether + rewards.
        assertEq(address(alice).balance, balAkice + rewards);

        // Chech that the variable substracts 1 after the withdrawal.
        assertEq(lend.totalSupplies(), supplies - 1);

        // Check that the variable is updated with the amount of the withdrawal.
        assertEq(lend.balanceSupply(), balSupply - amount2);

        // The withdraw function only works if the status is equal to SUPPLIER.
        // If data.stste is equal to BORROER, the function will revert.
        gateway.depositETH{value: amount2}();
        uint128 amountBorrow = _calculate40Percent(amount2);
        gateway.borrowETH(amountBorrow); //state = BORROWER

        // If the loan has not been paid, the withdraw function will revert.
        vm.expectRevert(
            LendingPool.MustRepayTheLoan__ThereIsNoDeposit.selector
        );
        gateway.withdrawETH(amount2);

        // When the loan is paid, the withdraw function works.
        uint256 interest = lend.calculateInterest(amountBorrow, address(alice));
        uint256 amountToRepay = amountBorrow + interest;
        gateway.repayETH{value: amountToRepay}(amountBorrow); //state = SUPPLIER
        gateway.withdrawETH(amount2);
    }

    function testFuzz_BorrowETH(uint128 amount) public {
        vm.assume(amount > 0.1 ether);
        // Check that user is not tHE address 0.
        vm.startPrank(address(0));
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        gateway.depositETH{value: amount}();
        vm.stopPrank();

        vm.startPrank(alice);

        // If the user has not made any deposit, the function will revert.
        vm.expectRevert(
            LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector
        );
        gateway.borrowETH(amount);

        // Deposit ETH.
        gateway.depositETH{value: amount}();

        // Save the value for checking after the borrow.
        uint256 balBorrow = lend.balanceBorrow();
        uint256 borrows = lend.totalBorrows();

        // If the amount is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.borrowETH(0 ether);

        // If the amount is greater than 40% of the amount deposited, the function will revert.
        vm.expectRevert(LendingPool.AmountExceeded.selector);
        gateway.borrowETH(amount);

        uint256 balAlice = address(alice).balance;

        // Calculate the maximum amount to borrow. 40%
        uint128 amountBorrow = _calculate40Percent(amount);

        // //Check the borrow emit.
        vm.expectEmit();
        emit Borrowed(address(alice), amountBorrow);

        // Borrow corect amount.
        gateway.borrowETH(amountBorrow);

        // Check that alice has the loan.
        assertEq(address(alice).balance, balAlice + amountBorrow);

        // Check has receive DebTokens.
        assertEq(iercDebToken.balanceOf(address(alice)), amountBorrow);

        // Check that the variable is updated with the amount of the borrow.
        assertEq(lend.balanceBorrow(), balBorrow + amountBorrow);

        // Chech that the variable adds 1 after the borrow.
        assertEq(lend.totalBorrows(), borrows + 1);

        // If the user has already borrowed, they will not be able to borrow again.
        vm.expectRevert(
            LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector
        );
        gateway.borrowETH(amount);
    }

    function testFuzz_RepayETH(uint128 amount) public {
        vm.assume(amount > 0.1 ether);
        // Check that user is not tHE address 0.
        vm.startPrank(address(0));
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        gateway.depositETH{value: amount}();
        vm.stopPrank();

        vm.startPrank(alice);

        vm.expectRevert(LendingPool.HasNotALoan.selector);
        gateway.repayETH{value: amount}(amount);

        // Deposit ETH  and borrow ETH.
        gateway.depositETH{value: amount}();
        uint128 amountBorrow = _calculate40Percent(amount);
        gateway.borrowETH(amountBorrow);

        // Check that alice has receiced DebTokens.
        assertEq(iercDebToken.balanceOf(address(alice)), amountBorrow);

        uint256 interest = lend.calculateInterest(amountBorrow, address(alice));
        uint256 amountToRepay = amountBorrow + interest;

        // If amount is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.repayETH{value: amountBorrow}(0);

        // If msg.value is less than amountToRepay, the funcion will revert.
        vm.expectRevert(LendingPool.InsuficientWeth.selector);
        gateway.repayETH{value: amountBorrow}(amountBorrow);

        // Save the values for checking after the repay.
        uint256 aliceBalance = address(alice).balance;
        uint256 balBorrow = lend.balanceBorrow();
        uint256 borrows = lend.totalBorrows();

        // Check the repay emit.
        vm.expectEmit();
        emit Repaied(address(alice), amountBorrow, interest);

        // If msg.value is correct and amount is correct, the function works.
        gateway.repayETH{value: amountToRepay}(amountBorrow);

        // Check alice's balances.
        assertEq(address(alice).balance, aliceBalance - amountToRepay);

        // Check that Alice has no DebTokens.
        assertEq(iercDebToken.balanceOf(address(alice)), 0 ether);

        // Check that the variable is updated with the amount of the borrow.
        assertEq(lend.balanceBorrow(), balBorrow - amountBorrow);

        // Chech that the variable substracts 1 after the repay.
        assertEq(lend.totalBorrows(), borrows - 1);
    }

    // This function calculates 40% of the amount to borrow to check the functions.
    function _calculate40Percent(uint128 amount) public pure returns (uint128) {
        uint128 t20Percent = amount / 5;
        uint128 f40Percent = t20Percent * 2;
        return f40Percent;
    }

    receive() external payable {}
}
