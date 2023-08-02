// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {LendingPool, IAToken} from "../src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import {AToken} from "../src/AToken.sol";


contract LendingPoolTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    
    IERC20 public ierc20TokenWeth;
    
    AToken public atoken;
    IERC20 public ierc20AToken;
    LendingPool public lend;
    address public bob;

    function setUp() public {

        vm.createSelectFork(MAINNET_RPC_URL);
        atoken = new AToken();
        ierc20AToken = IERC20(address(atoken));
        lend = new LendingPool(IAToken(address(atoken)));
        ierc20TokenWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        bob = makeAddr("bob");
        deal(address(ierc20TokenWeth), bob, 2 ether);
        vm.deal(bob, 2 ether);


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
        ierc20AToken.approve(address(lend), 2 ether);
        lend.withdraw(2 ether, bob);
        

    }

    
        


  
}