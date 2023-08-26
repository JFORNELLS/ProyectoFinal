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

    
    IERC20 public iercTokenWeth;
    
    AToken public atoken;
    DebToken public debtoken;
    WETH public weth;
    IERC20 public iercAToken;
    IERC20 public iercDebToken;
    WethGateWay public gateway;
    LendingPool public lend;
    address public bob;

    function setUp() public {

        atoken = new AToken(payable(address(lend)));
        debtoken = new DebToken();
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
        iercTokenWeth = IERC20(address(weth));

        bob = makeAddr("bob");
        deal(address(iercTokenWeth), bob, 2 ether);
        vm.deal(bob, 2 ether);
        deal(address(weth), address(lend), 4 ether);


    }

    function testDeposit() public {
        vm.startPrank(bob);
        
        iercTokenWeth.approve(address(lend), 0 ether);
        vm.expectRevert(LendingPool.AmountCannotBe0.selector);
        lend.deposit(0 ether, address(bob));
        iercTokenWeth.approve(address(lend), 2 ether);
        lend.deposit(2 ether, address(bob));
        assertEq(iercAToken.balanceOf(address(bob)), 2 ether);
        iercTokenWeth.approve(address(lend), 2 ether);
        vm.expectRevert(LendingPool.AlreadyHaveADeposit.selector);
        lend.deposit(2 ether, address(bob));
        console.log(address(lend));

    }

    function testWithdraw() public {
        vm.startPrank(bob);
        iercTokenWeth.approve(address(lend), 2 ether);
        lend.deposit(2 ether, address(bob));
        assertEq(iercAToken.balanceOf(address(bob)), 2 ether);

        iercAToken.approve(address(lend), 1 ether);
        lend.withdraw(1 ether, bob);
        uint256 rewards = lend.calculateRewards(1 ether, address(bob));
        assertEq(iercTokenWeth.balanceOf(address(bob)), 1 ether + rewards);
        assertEq(iercAToken.balanceOf(address(bob)), 1 ether);
        

    }

    function testBorrow() public {
        vm.startPrank(bob);
        console.log(iercTokenWeth.balanceOf(address(lend)));
        lend.borrow(2 ether, bob);
        assertEq(iercDebToken.balanceOf(address(bob)), 2 ether);
        assertEq(iercTokenWeth.balanceOf(address(bob)), 4 ether);
    }

    function testRepay() public {
        vm.startPrank(bob);
        iercTokenWeth.approve(address(lend), 2 ether);
        lend.deposit(2 ether, address(bob));
        lend.borrow(2 ether, bob);
        uint256 amountToRepay = lend.calculateInterest(1 ether, address(bob));
        iercTokenWeth.approve(address(lend), amountToRepay);
        //uint256 debt =  iercDebToken.balanceOf(address(bob));
        //iercDebToken.approve(address(lend), debt);
        

        lend.repay(1 ether, address(bob));
    }

}