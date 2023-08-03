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
        atoken = new AToken();
        debtoken = new DebToken();

        lend = new LendingPool(
            address(atoken), 
            address(debtoken), 
            payable(address(weth)), 
            payable(address(gateway))
            );

        gateway = new WethGateWay(
            address(atoken), 
            lend, 
            address(weth)
            );

        iercDebToken = IERC20(address(debtoken));
        iercAToken = IERC20(address(atoken));
        tokenWeth = IERC20(address(weth));
        
        alice = makeAddr("alice");
        vm.deal(alice, 2 ether);
        deal(address(iercAToken), alice, 2 ether);
        deal(address(tokenWeth), address(lend), 2 ether);
        
        
    }

    function testDepositETH() public {
        vm.startPrank(alice);
        assertEq(address(alice).balance, 2 ether);
        gateway.depositETH{value: 2 ether}();
        assertEq(address(alice).balance, 0);
        assertEq(iercAToken.balanceOf(address(alice)), 4 ether);

    }

    function testWithdrawETH() public {
        vm.startPrank(alice);
        gateway.depositETH{value: 2 ether}();
        iercAToken.approve(address(gateway), 2 ether);
        gateway.withdrawETH(2 ether);
        assertEq(address(alice).balance, 2 ether);
    }

    function testBorrowETH() public {
        vm.startPrank(alice);
        gateway.depositETH{value: 2 ether}();
        gateway.borrowETH(1 ether);
        assertEq(iercDebToken.balanceOf(address(alice)), 1 ether);
        assertEq(address(alice).balance, 1 ether);
    }



    receive() external payable {}
}