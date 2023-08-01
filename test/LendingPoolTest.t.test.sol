// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import {aToken} from "../src/aToken.sol";


contract LendingPoolTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    LendingPool public lend;
    address public tokenWeth;
    IERC20 public ierc20TokenWeth;
    IERC20 public ierc20Atoken;
    address public atoken;
    address public bob;
    
    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);

        lend = new LendingPool();
        atoken = (0x41C3c259514f88211c4CA2fd805A93F8F9A57504);
        tokenWeth = (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        ierc20TokenWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        ierc20Atoken = IERC20(0x41C3c259514f88211c4CA2fd805A93F8F9A57504);

        bob = makeAddr("bob");
        deal(address(tokenWeth), bob, 2 ether);
        vm.deal(bob, 2 ether);
        deal(address(atoken), 2 ether);


    }

    function testDeposit() public {
        vm.startPrank(bob);
        console.log(ierc20TokenWeth.balanceOf(bob));
        ierc20TokenWeth.approve(address(lend), 2 ether);
        lend.deposit(2 ether, address(bob));
        assertEq(ierc20Atoken.balanceOf(address(bob)), 2 ether);

    }

    function testWithdraw() public {
        vm.startPrank(bob);
        ierc20TokenWeth.approve(address(lend), 2 ether);
        lend.deposit(2 ether, address(bob));
        ierc20Atoken.approve(address(lend), 2 ether);
        //lend.withdraw(2 ether, bob);
        

    }

    
        


  
}