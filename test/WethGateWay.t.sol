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

    WETH public weth;
    IERC20 public tokenWeth;
    IERC20 public iercAToken;
    IERC20 public iercDebToken;
    address public alice;
    AToken public atoken; 
    DebToken public debtoken;
    LendingPool public lend;
    WethGateWay public gateway;
 

    function setUp() public {
        weth = new WETH();
        debtoken = new DebToken();
        atoken = new AToken(payable(address(lend)));
        

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
        tokenWeth = IERC20(address(weth));
        
        alice = makeAddr("alice");
        vm.deal(alice, 4 ether);
        vm.deal(address(lend), 10 ether);
        
        
        
    }
    

    function testDepositETH() public {
        vm.startPrank(alice);

        //Check that alice has 4 ether.
        assertEq(address(alice).balance, 4 ether);

        //Save the value for checking after the deposit.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();

        //If amount is 0 the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.depositETH{value: 0 ether}();

        //Deposit 2 ether.
        gateway.depositETH{value: 2 ether}();


        //Check that alice has 2 ether less.
        assertEq(address(alice).balance, 2 ether);

        //Check that alice has received 2 AToken.
        assertEq(iercAToken.balanceOf(address(alice)), 2 ether);

        //Check that the variable is updated with the amount of the deposit.
        assertEq(lend.balanceSupply(), balSupply + 2 ether);

        //Chech that the variable addsa + 1 after the deposit.
        assertEq(lend.totalSupplies(), supplies + 1);

        //If data.state in not equal to INITIAL, the function will revert.
        vm.expectRevert(LendingPool.AlreadyHaveADeposit.selector);
        gateway.depositETH{value: 2 ether}();
        console.log(address(lend));
       

    }

    function testWithdrawETH() public {
        gateway.depositETH{value: 10 ether}();
        //assertEq(address(lend).balance, 10 ether);
        vm.startPrank(alice);

        //Deposit 3 ether.
        gateway.depositETH{value: 3 ether}();
        

        //Check that alice has received 2 AToken.
        assertEq(iercAToken.balanceOf(address(alice)), 3 ether);
       
        //Save the profit calculation to check alice's balance.
        uint256 rewards = lend.calculateRewards(3 ether, address(alice));

        //Save the value for checking before the withdrawal.
        uint256 supplies = lend.totalSupplies();
        uint256 balSupply = lend.balanceSupply();

        //Approve to WethGateWay contract to move 2 AToken.
        iercAToken.approve(address(gateway), 3 ether);

        //Withdraw 3 ether.
        gateway.withdrawETH(3 ether);

        //Check that alice has 0 AToken.
        assertEq(iercAToken.balanceOf(address(alice)), 0 ether);

        //Check that alice has 4 ether + rewards.
        assertEq(address(alice).balance, 4 ether + rewards);

        //Chech that the variable abstract 1 after the withdrawal.
        assertEq(lend.totalSupplies(), supplies - 1);

        //Check that the variable is updated with the amount of the withdrawal.
        assertEq(lend.balanceSupply(), balSupply - 3 ether);

        
        //If the user does not have ATokens, 
        //they will not be able to use the withdraw function and will revert
        vm.expectRevert(stdError.arithmeticError);
        gateway.withdrawETH(1 ether);

        //If amount to withdraw is 0 the function will revert.
        gateway.depositETH{value: 3 ether}();
        iercAToken.approve(address(gateway), 0 ether);
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.withdrawETH(0 ether);



        //The withdraw function only works if the status is equal to SUPPLIER.
        //If data.stste is equal to BORROER, the function will revert. 
        gateway.borrowETH(1 ether);   //state = BORROWER
        iercAToken.approve(address(gateway), 1 ether);

        //If the loan has not been paid, the withdraw function will revert.
        vm.expectRevert(LendingPool.MustRepayTheLoan__ThereIsNoDeposit.selector);
        gateway.withdrawETH(1 ether);

        //When the loan is paid, the withdraw function works.
        uint256 amountToRepay = lend.calculateInterest(1 ether, address(alice));
        iercDebToken.approve(address(gateway), 1 ether);
        gateway.repayETH{value: amountToRepay}(1 ether);   //state = SUPPLIER
        iercAToken.approve(address(gateway), 3 ether);
        gateway.withdrawETH(3 ether);      



       
    }

    function testBorrowETH() public {
        vm.startPrank(alice);
        //If the user has not made any deposit, the function will revert.
        vm.expectRevert(LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector);
        gateway.borrowETH(0.80 ether);

        gateway.depositETH{value: 2 ether}();

        //Save the value for checking before the borrow.
        uint256 balBorrow = lend.balanceBorrow();
        uint256 borrows = lend.totalBorrows();

        //If the amount is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.borrowETH(0 ether);

        //If the amount is greater than 40% of the amount deposited, the function will revert.
        vm.expectRevert(LendingPool.AmountExceeded.selector);
        gateway.borrowETH(1 ether);

        //Borrow corect amount.
        gateway.borrowETH(0.40 ether);

        //Check that alice has the loan.
        assertEq(address(alice).balance, 2.4 ether);

        //Check has receive DebTokens.
        assertEq(iercDebToken.balanceOf(address(alice)), 0.40 ether);

        //Check that the variable is updated with the amount of the borrow.
        assertEq(lend.balanceBorrow(), balBorrow + 0.40 ether);

        //Chech that the variable adds 1 after the borrow.
        assertEq(lend.totalBorrows(), borrows + 1);

        //If the user already has a loan, the function will revert.
        vm.expectRevert(LendingPool.ThereIsNoDeposit_AlreadyRequestedALoan.selector);
        gateway.borrowETH(0.40 ether);

    

    }

    function testRepayETH() public {
        vm.startPrank(alice);

        //If the user has not DebTokens, the function will revert.
        iercDebToken.approve(address(gateway), 1 ether);
        vm.expectRevert(stdError.arithmeticError);
        gateway.repayETH(1 ether);

        gateway.depositETH{value: 2 ether}(); //state = SUPPLIER
        gateway.borrowETH(0.80 ether);

        //Check that alice has receiced DebTokens.
        assertEq(iercDebToken.balanceOf(address(alice)), 0.80 ether);

        //If amount is 0, the function will revert.
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        gateway.repayETH{value: 0 ether}(0);

        //If msg.value is less than amountToRepay, the funcion will revert.
        uint256 amountToRepay = lend.calculateInterest(0.80 ether, address(alice));
        iercDebToken.approve(address(gateway), 0.80 ether);
        vm.expectRevert(LendingPool.InsuficientWeth.selector);
        gateway.repayETH{value: 0.80 ether}(0.80 ether);

        //if the amount passed by parameter is greater than the amount of the user's debtTokens,
        //the function will revert.
        vm.expectRevert(stdError.arithmeticError);
        gateway.repayETH{value: amountToRepay}(1 ether);

        uint256 aliceBalance = address(alice).balance;
        //If msg.value is correct and amount is correct, the function works.
        gateway.repayETH{value: amountToRepay}(0.80 ether);

        //Check alice's balances.
        assertEq(address(alice).balance, aliceBalance - amountToRepay);
        assertEq(iercDebToken.balanceOf(address(alice)), 0 ether);

        
        
        
    }



    



    receive() external payable {}
}