// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";
import "../src/WethGateWay.sol";
import "../lib/solmate/src/tokens/WETH.sol";

contract LendingPoolTest is Test {
    event Deposited(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount, uint256 rewards);

    event Borrowed(address indexed user, uint256 amount);

    event Repaied(address indexed user, uint256 amount, uint256 interest);

    IERC20 public iercWeth;

    AToken public atoken;
    DebToken public debtoken;
    WETH public weth;
    IERC20 public iercAToken;
    IERC20 public iercDebToken;
    WethGateWay public gateway;
    LendingPool public lend;
    address public bob;

    function setUp() public {
        atoken = new AToken(
            payable(0xc7183455a4C133Ae270771860664b6B7ec320bB1)
        );
        debtoken = new DebToken(
            payable(0xc7183455a4C133Ae270771860664b6B7ec320bB1)
        );

        weth = new WETH();

        gateway = new WethGateWay(
            address(atoken),
            lend,
            address(weth),
            address(debtoken)
        );

        lend = new LendingPool(
            address(atoken),
            address(debtoken),
            payable(address(weth)),
            payable(address(gateway))
        );

        iercDebToken = IERC20(address(debtoken));
        iercAToken = IERC20(address(atoken));
        iercWeth = IERC20(address(weth));

        bob = makeAddr("bob");
        deal(address(iercWeth), bob, 2 ** 128 wei);
        deal(address(iercWeth), address(0), 1 ether);
        deal(address(iercWeth), address(lend), 2 ** 200 wei);
    }

    function testFuzz_Deposit(uint128 amount) public {
        vm.assume(amount > 0.1 ether);
        // Check tha user is not the address 0.
        vm.startPrank(address(0));
        iercWeth.approve(address(lend), amount);
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.deposit(address(0), amount);
        vm.stopPrank();

        vm.startPrank(bob);

        // If amount is 0 the function will revert.
        iercWeth.approve(address(lend), 0 ether);
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.deposit(address(bob), 0 ether);

        // Approve to LendingPool contract TO MOVE WETH.
        iercWeth.approve(address(lend), amount);

        // Save the value for checking after the deposit.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();
        uint256 balanceBob = iercWeth.balanceOf(address(bob));

        // Ckeck the deposit event.
        vm.expectEmit();
        emit Deposited(address(bob), amount);

        // Deposit WETH.
        lend.deposit(address(bob), amount);

        // Check tha Bob has receive amount ATokens.
        assertEq(iercAToken.balanceOf(address(bob)), amount);

        // Check that Bob has amount WETH tokens less.
        assertEq(iercWeth.balanceOf(address(bob)), balanceBob - amount);

        // Check that the variable is updated with the amount of the deposit.
        assertEq(lend.balanceSupply(), balSupply + amount);

        // Chech that the variable addsa + 1 after the deposit.
        assertEq(lend.totalSupplies(), supplies + 1);

        // If data.state in not equal to INITIAL, the function will revert.
        iercWeth.approve(address(lend), amount);
        vm.expectRevert(LendingPool.AlreadyHaveADeposit.selector);
        lend.deposit(address(bob), amount);
    }

    function testFuzz_Withdraw(uint128 amount) public {
        vm.assume(amount > 0.1 ether);
        vm.startPrank(bob);
        // Save the value of amount2 -1 to verify the check (amount > data.amountDeposit).
        uint128 amount2 = amount - 1;

        // If the user does has not a deposit, the function will revert.
        vm.expectRevert(
            LendingPool.MustRepayTheLoan__ThereIsNoDeposit.selector
        );
        lend.withdraw(bob, amount2);

        // Deposit amount WETH Tokens.
        iercWeth.approve(address(lend), amount2);
        lend.deposit(address(bob), amount2);

        // Save the value for checking before the withdrawal.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();

        // If amount to withdraw is 0 the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.withdraw(bob, 0);
        vm.stopPrank();

        // If the withdrawal amount is greater than the deposit amount,
        // the function will revert.
        vm.expectRevert(LendingPool.AmountMustBeLess.selector);
        lend.withdraw(address(bob), amount2 + 1);

        // Check that user is not the address 0.
        vm.startPrank(address(0));
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.withdraw(address(0), amount2);
        vm.stopPrank();

        vm.startPrank(bob);
        // Save the profit calculation to check bob's balance.
        uint256 balanceBob = iercWeth.balanceOf(address(bob));
        uint256 rewards = lend.calculateRewards(amount2, address(bob));

        // Check the withdraw emit.
        vm.expectEmit();
        emit Withdrawn(address(bob), amount2, rewards);

        // Withdraw amount WETH.
        lend.withdraw(bob, amount2);

        // Chec that bob has recieve  WETH + rewards.
        assertEq(
            iercWeth.balanceOf(address(bob)),
            balanceBob + amount2 + rewards
        );

        // Check that bob does not have  ATokens.
        assertEq(iercAToken.balanceOf(address(bob)), 0 ether);

        // Chech that the variable substracts 1 after the withdrawal.
        assertEq(lend.totalSupplies(), supplies - 1);

        // Check that the variable is updated with the amount of the withdrawal.
        assertEq(lend.balanceSupply(), balSupply - amount2);

        // The withdraw function only works if the status is equal to SUPPLIER.
        // If data.stste is equal to BORROER, the function will revert.
        iercWeth.approve(address(lend), amount2);
        lend.deposit(bob, amount2);

        // The maximum amount to borrow is 40 percent of the deposit.
        uint128 amountBorrow = _calculate40Percent(amount2);

        // Save the Bob's balance for checking after borrow, repay and withdraw.
        uint256 balBob = iercWeth.balanceOf(address(bob));
        lend.borrow(bob, amountBorrow); //state.BORROWER.

        // If the loan has not been paid, the withdraw function will revert.
        vm.expectRevert(
            LendingPool.MustRepayTheLoan__ThereIsNoDeposit.selector
        );
        lend.withdraw(bob, amount2);

        // When the loan is paid, the withdraw function works.
        uint256 interest = lend.calculateInterest(amountBorrow, address(bob));
        uint256 rewards2 = lend.calculateRewards(amount2, address(bob));
        uint256 amountToRepay = amountBorrow + interest;

        iercWeth.approve(address(lend), amountToRepay);
        lend.repay(bob, amountBorrow);
        lend.withdraw(bob, amount2);

        // Check Bob's balance.
        assertEq(
            iercWeth.balanceOf(address(bob)),
            ((balBob + amountBorrow) + amount2 + rewards2) - amountToRepay
        );

        iercWeth.approve(address(lend), amount2);
        lend.deposit(address(bob), amount2);
    }

    function testFuzz_Borrow(uint128 amount) public {
        vm.assume(amount > 0.1 ether);
        // Check that user is not the address 0.
        vm.startPrank(address(0));
        iercWeth.approve(address(lend), amount);
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.deposit(address(0), amount);
        vm.stopPrank();

        vm.startPrank(bob);
        // If the user has not made any deposit, the function will revert.
        vm.expectRevert(
            LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector
        );
        lend.borrow(address(bob), amount);

        // Deposit WETH Tokens.
        iercWeth.approve(address(lend), amount);
        lend.deposit(address(bob), amount);

        // Save the value for checking after the borrow.
        uint256 balBorrow = lend.balanceBorrow();
        uint256 borrows = lend.totalBorrows();
        uint256 balanceBob = iercWeth.balanceOf(address(bob));

        // If the amount to borrow is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.borrow(address(bob), 0 ether);

        // If the amount to borrow is greater than 40% of the amount deposited,
        // the function will revert.
        vm.expectRevert(LendingPool.AmountExceeded.selector);
        lend.borrow(address(bob), amount);

        // The maximum amount to borrow is 40 percent of the deposit.
        uint128 amountBorrow = _calculate40Percent(amount);

        // Chech the borrow emit.
        vm.expectEmit();
        emit Borrowed(address(bob), amountBorrow);

        // Borrow amountBorrow WETH Tokens.
        lend.borrow(address(bob), amountBorrow);

        // Check that bob has the loan.
        assertEq(iercWeth.balanceOf(address(bob)), balanceBob + amountBorrow);

        // Check has receive DebTokens.
        assertEq(iercDebToken.balanceOf(address(bob)), amountBorrow);

        // Check that the variable is updated with the amount of the borrow.
        assertEq(lend.balanceBorrow(), balBorrow + amountBorrow);

        // Chech that the variable adds 1 after the borrow.
        assertEq(lend.totalBorrows(), borrows + 1);

        // If the user has already borrowed, they will not be able to borrow again.
        vm.expectRevert(
            LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector
        );
        lend.borrow(address(bob), amount);
    }

    function testFuzz_Repay(uint128 amount) public {
        vm.assume(amount > 0.1 ether);
        // Check that user is not the address 0.
        vm.startPrank(address(0));
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.repay(address(0), amount);
        vm.stopPrank();

        vm.startPrank(bob);

        // If user has not borrow the functin will revert.
        vm.expectRevert(LendingPool.HasNotALoan.selector);
        lend.repay(address(bob), amount);

        // Deposit amount WETH Tokens and borrow 40% WETH Tokens.
        iercWeth.approve(address(lend), amount);
        lend.deposit(address(bob), amount);
        uint128 amountBorrow = _calculate40Percent(amount) - 1;
        lend.borrow(address(bob), amountBorrow);

        // If amount to reapy is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.repay(address(bob), 0 ether);

        // If the amount to be paid is greater than the amount borrowed,
        // the function will revert.
        vm.expectRevert(LendingPool.AmountExceedsDebt.selector);
        lend.repay(address(bob), amountBorrow + 1);

        // If the user has not suficient WETH in his wallet, the funcion will revert.
        // Give to bob insuficient WETH.
        deal(address(iercWeth), bob, 0.0000001 ether);
        uint256 interest = lend.calculateInterest(amountBorrow, address(bob));
        uint256 amountToRepay = amountBorrow + interest;
        iercWeth.approve(address(lend), amountToRepay);
        vm.expectRevert(LendingPool.InsuficientWeth.selector);
        lend.repay(address(bob), amountBorrow);

        // GIve to bob suficient to repay.
        deal(address(iercWeth), bob, 2 ** 128 wei);

        uint256 balanceBob = iercWeth.balanceOf(address(bob));

        // Approve to LendinPool to move amount to repay.
        iercWeth.approve(address(lend), amountToRepay);

        // Check the repay emit.
        vm.expectEmit();
        emit Repaied(address(bob), amountBorrow, interest);

        // Reaay the loan.
        lend.repay(address(bob), amountBorrow);

        // Check Bob's balance,
        assertEq(iercWeth.balanceOf(address(bob)), balanceBob - amountToRepay);

        // Chech that Bob has no DebTokens.
        assertEq(iercDebToken.balanceOf(address(bob)), 0 ether);
    }

    function testTransfer() public {
        assertTrue(lend.transfer(weth, address(bob), 2 ether));
    }

    function testTransferFrom() public {
        vm.startPrank(bob);
        iercWeth.approve(address(lend), 2 ether);
        assertTrue(
            lend.transferFrom(weth, address(bob), address(lend), 2 ether)
        );
    }

    // This function calculates 40% of the amount to borrow to check the functions
    function _calculate40Percent(uint128 amount) public pure returns (uint128) {
        uint128 t20Percent = amount / 5;
        uint128 f40Percent = t20Percent * 2;
        return f40Percent;
    }
}
