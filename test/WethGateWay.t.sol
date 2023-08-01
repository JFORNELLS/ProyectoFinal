// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {WethGateWay} from "../src/WethGateWay.sol";
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {aToken} from "../src/aToken.sol";


contract WethGateWayTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    WethGateWay public gateway;
    IERC20 public tokenWeth;
    IERC20 public ierc20Atoken;
    address public alice;
    address public atoken;
 

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);
        
        tokenWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        ierc20Atoken = IERC20(0x41C3c259514f88211c4CA2fd805A93F8F9A57504);
        atoken = (0x41C3c259514f88211c4CA2fd805A93F8F9A57504);
        gateway = new WethGateWay();
        alice = makeAddr("alice");
        vm.deal(alice, 2 ether);
        deal(address(ierc20Atoken), alice, 2 ether);
        
        
        
        
    }

    function testDepositETH() public {
        vm.startPrank(alice);
        assertEq(address(alice).balance, 2 ether);
        gateway.depositETH{value: 2 ether}();
        assertEq(address(alice).balance, 0);
        assertEq(ierc20Atoken.balanceOf(address(alice)), 4 ether);

    }

    function testWithdrawETH() public {
        vm.startPrank(alice);
        console.log(ierc20Atoken.balanceOf(alice));
        gateway.depositETH{value: 2 ether}();
        ierc20Atoken.approve(address(gateway), 2 ether);
        gateway.withdrawETH(2 ether);
        assertEq(address(alice).balance, 2 ether);
    }

    

   

 
    receive() external payable {}
}