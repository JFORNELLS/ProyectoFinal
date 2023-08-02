//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {WethGateWay} from "../src/WethGateWay.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";
import "../src/DebToken.sol";
import "../src/aToken.sol";
import "../lib/solmate/src/tokens/WETH.sol";


contract WethGateWayTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    WETH public weth;
    IERC20 public tokenWeth;
    IERC20 public ierc20AToken;
    IERC20 public ierc20DebToken;
    address public alice;
    AToken public atoken; 
    DebToken public debtoken;
    LendingPool public lend;
    WethGateWay public gateway;
 

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);
        atoken = new AToken();
        weth = new WETH();
        debtoken = new DebToken();
        
        
        
        lend = new LendingPool(address(atoken), address(debtoken), payable(address(weth)));
        gateway = new WethGateWay(address(atoken), lend, address(weth));

        ierc20DebToken = IERC20(address(debtoken));
        ierc20AToken = IERC20(address(atoken));
        tokenWeth = IERC20(address(weth));
        
        alice = makeAddr("alice");
        vm.deal(alice, 2 ether);
        deal(address(ierc20AToken), alice, 2 ether);
        deal(address(tokenWeth), address(lend), 2 ether);
        
        
    }

    function testDepositETH() public {
        vm.startPrank(alice);
        assertEq(address(alice).balance, 2 ether);
        gateway.depositETH{value: 2 ether}();
        assertEq(address(alice).balance, 0);
        assertEq(ierc20AToken.balanceOf(address(alice)), 4 ether);

    }

    function testWithdrawETH() public {
        vm.startPrank(alice);
        console.log(ierc20AToken.balanceOf(alice));
        gateway.depositETH{value: 2 ether}();
        ierc20AToken.approve(address(gateway), 2 ether);
        gateway.withdrawETH(2 ether);
        assertEq(address(alice).balance, 2 ether);
    }

    function testBorrowETH() public {
        vm.startPrank(alice);
        console.log(tokenWeth.balanceOf(address(lend)));
        gateway.borrowETH(2 ether);
        //console.log(tokenWeth.balanceOf(address(lend)));
        //assertEq(ierc20DebToken.balanceOf(address(alice)), 2 ether);
        //assertEq(address(alice).balance, 4 ether);
    }



    receive() external payable {}
}