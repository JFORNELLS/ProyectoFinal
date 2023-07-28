// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import {aToken} from "../src/aToken.sol";


contract LendingPoolTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    LendingPool public lend;
    aToken public atoken;
    IERC20 public tokenWeth;

    address public bob;
   


    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);
        lend = new LendingPool();
        atoken = new aToken();
        tokenWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        bob = makeAddr("bob");
        deal(address(tokenWeth), bob, 1 ether);
        deal(address(tokenWeth), address(this), 2 ether);
        vm.deal(address(lend), 2 ether);
        
    }

    function testDeposit() public {
        vm.startPrank(bob);
        console.log("bob weth", tokenWeth.balanceOf(address(bob)));
        IERC20(tokenWeth).approve(address(lend), 1 ether);
        lend.deposit(1 ether);
        console.log("bob weth", tokenWeth.balanceOf(address(bob)));
        lend.getATokenBalance(address(bob));
        console.log("mapping Weth" ,lend.balanceWeth(address(bob)));
        

    }

    function testBorrowLend() public {
        vm.startPrank(bob);
        lend.borrow(2 ether);
        
    }
}