// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
//import "../lib/solmate/src/tokens/WETH.sol";
//import {LendingPool} from "../src/LendingPool.sol";
import {WethGateWay, ILend} from "../src/WethGateWay.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
//import "../openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../src/LendingPool.sol";
import "../src/aToken.sol";


contract WethGateWayTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    WethGateWay public gateway;
    address public alice;
    IERC20 public tokenWeth;
    LendingPool public lend;
    ILend public ilend;
    aToken public atoken;
    

   

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);
        gateway = new WethGateWay();
        atoken = new aToken();
        lend = new LendingPool();
        tokenWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        
        
        alice = makeAddr("alice");
        vm.deal(alice, 100 ether);
        deal(address(tokenWeth), alice, 2 ether);
        //deal(address(atoken), alice, 2 ether);
    }

    function testDeposit() public {
        vm.startPrank(alice);
        console.log("Alice ETH", address(alice).balance);
        gateway.depositETH{value: 10 ether}(2 ether);
        IERC20(address(atoken)).approve(alice, 2 ether);
        gateway.withdrawETH(2 ether);
        
  
        
        
       
        
    }
   

 
    receive() external payable {}
}