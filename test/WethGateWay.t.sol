// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {WethGateWay} from "../src/WethGateWay.sol";
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {aToken} from "../src/aToken.sol";
import "../src/Data.sol";


contract WethGateWayTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    WethGateWay public gateway;
    address public alice;
    IERC20 public tokenWeth;
    LendingPool public lend;
    aToken public atoken;
    Dates public update = new Dates();

   

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);
        gateway = new WethGateWay();
        atoken = new aToken();
        lend = new LendingPool();
        update = new Dates();
        tokenWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        
        
        alice = makeAddr("alice");
        vm.deal(alice, 100 ether);
        deal(address(tokenWeth), alice, 2 ether);
        deal(address(atoken), alice, 2 ether);
        deal(address(tokenWeth), address(lend), 2 ether);
    }

    function testDepositETH() public {
        vm.startPrank(alice);
        console.log("Alice ETH", address(alice).balance);
        gateway.depositETH{value: 10 ether}(2 ether);
        IERC20(address(atoken)).approve(address(gateway), 2 ether);
        gateway.withdrawETH(2 ether);

    }

    function testWithdrawETH() public {
        //gateway.withdrawETH();
    }


    function testBorrow() public {
        //vm.startPrank(alice);
        //console.log("wetLen", tokenWeth.balanceOf(address(lend)));
        //gateway.borrowETH(2 ether);
        
        

    }
   

 
    receive() external payable {}
}