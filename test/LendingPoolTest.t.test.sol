// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";
import "../src/WethGateWay.sol";
import "../lib/solmate/src/tokens/WETH.sol";



contract LendingPoolTest is Test {


    event Deposited(
        address indexed user,
        uint256 amount
    );

    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 rewards
    );

    event Borrowed(
        address indexed user,
        uint256 amount
    );

    event Repaied(
        address indexed user,
        uint256 amount,
        uint256 interest
    );

  
    IERC20 public iercWeth;
    
    AToken public atoken;
    DebToken public debtoken;
    WETH public weth;
    IERC20 public iercAToken;
    IERC20 public iercDebToken;
    WethGateWay public gateway;
    LendingPool public lend;
    address public bob;
    address public owner;


    function setUp() public {

        atoken = new AToken(payable(address(lend)));
        debtoken = new DebToken(payable(address(lend)));
        weth = new WETH();
        owner = makeAddr("owner");
        
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
            payable(address(gateway)),
            address(owner)
            );

        iercDebToken = IERC20(address(debtoken));
        iercAToken = IERC20(address(atoken));
        iercWeth = IERC20(address(weth));
        

        bob = makeAddr("bob");
        deal(address(iercWeth), bob, 3 ether);
        deal(address(iercWeth), address(0), 1 ether);
        deal(address(iercWeth), address(lend), 1000 ether);
        vm.deal(bob, 2 ether);

    }

    
  
    function testDeposit() public {
        // Check tha user is not the address 0.
        vm.startPrank(address(0));
        iercWeth.approve(address(lend), 1 ether);
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.deposit(address(0), 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        
        // If amount is 0 the function will revert.
        iercWeth.approve(address(lend), 0 ether);
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.deposit(address(bob), 0 ether);

        // Approve to LendingPool contract to move 2 AToken.
        iercWeth.approve(address(lend), 2 ether);

        // Save the value for checking after the deposit.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();

        // Ckeck the deposit event.
        vm.expectEmit(true, false, false, true, address(lend));
        emit Deposited(address(bob), 2 ether);
        
        // Deposit 2 WETH tokens
        lend.deposit(address(bob), 2 ether);   

        // Check tha Bob has receive 2 ATokens.
        assertEq(iercAToken.balanceOf(address(bob)), 2 ether);

        // Check that Bob has 2 WETH tokens less.
        assertEq(iercWeth.balanceOf(address(bob)), 1 ether);

        // Check that the variable is updated with the amount of the deposit.
        assertEq(lend.balanceSupply(), balSupply + 2 ether);

        // Chech that the variable addsa + 1 after the deposit.
        assertEq(lend.totalSupplies(), supplies + 1);


        // If data.state in not equal to INITIAL, the function will revert.
        iercWeth.approve(address(lend), 2 ether);
        vm.expectRevert(LendingPool.AlreadyHaveADeposit.selector);
        lend.deposit(address(bob), 2 ether);

        
    }
  

    function testWithdraw() public {
        deal(address(iercWeth), bob, 100 ether);
        vm.startPrank(bob);

        // If the user does has not a deposit, the function will revert.
        iercAToken.approve(address(lend), 1 ether);
        vm.expectRevert(LendingPool.MustRepayTheLoan__ThereIsNoDeposit.selector);
        lend.withdraw(bob, 1 ether);
        
        // Deposit 2 WETH Tokens.
        iercWeth.approve(address(lend), 2 ether);
        lend.deposit(address(bob), 2 ether);

        // Save the value for checking before the withdrawal.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();

        // If amount to withdraw is 0 the function will revert.
        iercAToken.approve(address(lend), 0 ether);
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.withdraw(bob, 0 ether);
        vm.stopPrank();

        // If the withdrawal amount is greater than the deposit amount, 
        // the function will revert.
        vm.expectRevert(LendingPool.AmountMustBeLess.selector);
        lend.withdraw(address(bob), 3 ether);


        // Check that user is not the address 0.
        vm.startPrank(address(0));
        iercAToken.approve(address(0), 1 ether);
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.withdraw(address(0), 1 ether);
        vm.stopPrank();

        // Save the profit calculation to check bob's balance.
        uint256 rewards = lend.calculateRewards(2 ether, address(bob));
        vm.startPrank(bob);

        // Approve to LendingPool contract to move 2 AToken.
        iercAToken.approve(address(lend), 2 ether);

        // Check the withdraw emit.
        vm.expectEmit(true, false, false, true, address(lend));
        emit Withdrawn(address(bob), 2 ether, rewards);

        // Withdraw 2 ether.
        lend.withdraw(bob, 2 ether);

        // Chec that bob has recieve 2 WETH + rewards.
        assertEq(iercWeth.balanceOf(address(bob)), 100 ether + rewards);

        // Check that bob does not have 2 ATokens.
        assertEq(iercAToken.balanceOf(address(bob)), 0 ether);

        // Save the Bob's balance for checking after borrow, repay and withdraw.
        uint256 balBob = iercWeth.balanceOf(address(bob));

        // Chech that the variable substracts 1 after the withdrawal.
        assertEq(lend.totalSupplies(), supplies - 1);

        //Check that the variable is updated with the amount of the withdrawal.
        assertEq(lend.balanceSupply(), balSupply - 2 ether);

        // The withdraw function only works if the status is equal to SUPPLIER.
        // If data.stste is equal to BORROER, the function will revert.
        iercWeth.approve(address(lend), 2 ether);
        lend.deposit(bob, 2 ether);
        lend.borrow(bob, 0.80 ether); //state.BORROWER.

        // If the loan has not been paid, the withdraw function will revert.
        iercAToken.approve(address(lend), 2 ether);
        vm.expectRevert(LendingPool.MustRepayTheLoan__ThereIsNoDeposit.selector);
        lend.withdraw(bob, 2 ether);

        
        uint256 interest = lend.calculateInterest(0.80 ether, address(bob));
        uint256 amountToRepay = 0.80 ether + interest;
        iercWeth.approve(address(lend), amountToRepay);

        // When the loan is paid, the withdraw function works.
        lend.repay(bob, 0.80 ether);
        lend.withdraw(bob, 2 ether);

        // Check Bob's balance.
        assertEq(iercWeth.balanceOf(address(bob)), balBob - interest + rewards);
        
    }

    function testBorrow() public {
        // Check that user is not the address 0.
        vm.startPrank(address(0));
        iercWeth.approve(address(lend), 1 ether);
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.deposit(address(0), 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        // If the user has not made any deposit, the function will revert.
        vm.expectRevert(LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector);
        lend.borrow(address(bob), 0.80 ether);

        // Deposit 2 WETH Tokens.
        iercWeth.approve(address(lend), 2 ether);
        lend.deposit(address(bob), 2 ether);

        // Save the value for checking after the borrow.
        uint256 balBorrow = lend.balanceBorrow();
        uint256 borrows = lend.totalBorrows();

        // If the amount to borrow is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.borrow(address(bob), 0 ether);

        // If the amount to borrow is greater than 40% of the amount deposited, 
        // the function will revert.
        vm.expectRevert(LendingPool.AmountExceeded.selector);
        lend.borrow(address(bob), 1 ether);

        // Chech the borrow emit.
        vm.expectEmit(true, false, false, true, address(lend));
        emit Borrowed(address(bob), 0.80 ether);

        // Borrow 0.80 WETH Tokens.
        lend.borrow(address(bob), 0.80 ether);

        // Check that alice has the loan.
        assertEq(iercWeth.balanceOf(address(bob)), 1.8 ether);

        // Check has receive DebTokens.
        assertEq(iercDebToken.balanceOf(address(bob)), 0.80 ether);

        // Check that the variable is updated with the amount of the borrow.
        assertEq(lend.balanceBorrow(), balBorrow + 0.80 ether);

        // Chech that the variable adds 1 after the borrow.
        assertEq(lend.totalBorrows(), borrows + 1);

        // If the user has already borrowed, they will not be able to borrow again.
        vm.expectRevert(LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector);
        lend.borrow(address(bob), 0.80 ether);

    }

    function testRepay() public {
        // Check that user is not the address 0.
        vm.startPrank(address(0));
        vm.expectRevert(LendingPool.addressCannotBe0x0.selector);
        lend.repay(address(0), 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        
        // If the user has not DebTokens, the function will revert.
        iercDebToken.approve(address(lend), 3 ether);
        vm.expectRevert(LendingPool.HasNotALoan.selector);
        lend.repay(address(bob), 3 ether);

        // Deposit 2 WETH Tokens and borrow 0.80 WETH Tokens.
        iercWeth.approve(address(lend), 3 ether);
        lend.deposit(address(bob), 3 ether); 
        lend.borrow(address(bob), 0.80 ether);

        // If amount to reapy is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.repay(address(bob), 0 ether);

        // If the amount to be paid is greater than the amount borrowed, 
        // the function will revert.
        vm.expectRevert(LendingPool.AmountExceedsDebt.selector);
        lend.repay(address(bob), 1 ether);

        // If the user has not suficient WETH in his wallet, the funcion will revert.
        uint256 interest = lend.calculateInterest(0.80 ether, address(bob));
        uint256 amountToRepay = 0.80 ether + interest;
        iercWeth.approve(address(lend), amountToRepay);
        vm.expectRevert(LendingPool.InsuficientWeth.selector);
        lend.repay(address(bob), 0.80 ether);

        // Give to Bob 200 WETH more to pay the loan.
        deal(address(iercWeth), bob, 200 ether);      

        // Approve to LendinPool to move amount to repay.
        iercWeth.approve(address(lend), amountToRepay);

        // Check the repay emit.
        vm.expectEmit(true, false, false, true, address(lend));
        emit Repaied(address(bob), 0.80 ether, interest);
        
        // Reaay the loan.
        lend.repay(address(bob), 0.80 ether);

        // Check Bob's balance,
        assertEq(iercWeth.balanceOf(address(bob)), 200 ether - amountToRepay);

        // Chech that Bob has no DebTokens.
        assertEq(iercDebToken.balanceOf(address(bob)), 0 ether);
        
    }

    function testRatesUpdate() public {
        // Only the owner can call this function,
        // If the caller no is not the ownner the function will revert.
        vm.expectRevert();
        lend.ratesUpdate(4 ether, 4 ether);

        // The owner calls the function.
        vm.prank(owner);
        lend.ratesUpdate(4 ether, 4 ether);

        // Check that the variables are updated correctly.
        assertEq(lend.rewardsRate(), 4 ether);
        assertEq(lend.interestRate(), 4 ether);
        
    }

  
}  