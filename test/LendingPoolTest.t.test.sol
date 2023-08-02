// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";


contract LendingPoolTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    
    IERC20 public ierc20TokenWeth;
    
    AToken public atoken;
    DebToken public debtoken;
    IERC20 public ierc20AToken;
    IERC20 public ierc20DebToken;
    LendingPool public lend;
    address public bob;

    function setUp() public {

        vm.createSelectFork(MAINNET_RPC_URL);
        atoken = new AToken();
        debtoken = new DebToken();
        ierc20AToken = IERC20(address(atoken));
        ierc20DebToken = IERC20(address(debtoken));
        lend = new LendingPool(address(atoken), address(debtoken));
        ierc20TokenWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        bob = makeAddr("bob");
        deal(address(ierc20TokenWeth), bob, 2 ether);
        vm.deal(bob, 2 ether);
        deal(address(ierc20TokenWeth), address(lend), 2 ether);


    }

    function testDeposit() public {
        vm.startPrank(bob);
        console.log(ierc20TokenWeth.balanceOf(bob));
        ierc20TokenWeth.approve(address(lend), 2 ether);
        lend.deposit(2 ether, address(bob));
        assertEq(ierc20AToken.balanceOf(address(bob)), 2 ether);

    }

    function testWithdraw() public {
        vm.startPrank(bob);
        ierc20TokenWeth.approve(address(lend), 2 ether);
        lend.deposit(2 ether, address(bob));
        assertEq(ierc20AToken.balanceOf(address(bob)), 2 ether);
        ierc20AToken.approve(address(lend), 2 ether);
        lend.withdraw(2 ether, bob);
        

    }

    function testBorrow() public {
        vm.startPrank(bob);
        console.log(ierc20TokenWeth.balanceOf(address(lend)));
        lend.borrow(2 ether, bob);
        assertEq(ierc20DebToken.balanceOf(address(bob)), 2 ether);
        assertEq(ierc20TokenWeth.balanceOf(address(bob)), 4 ether);
    }

}