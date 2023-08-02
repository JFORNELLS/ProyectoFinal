// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";
import {WETH} from "../lib/solmate/src/tokens/WETH.sol";


contract LendingPoolTest is Test {
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    
    IERC20 public ierc20TokenWeth;
    
    AToken public atoken;
    DebToken public debtoken;
    WETH public iweth;
    IERC20 public ierc20AToken;
    IERC20 public ierc20DebToken;
    LendingPool public lend;
    address public bob;

    function setUp() public {

        vm.createSelectFork(MAINNET_RPC_URL);
        atoken = new AToken();
        debtoken = new DebToken();
        iweth = new WETH();
        ierc20DebToken = IERC20(address(debtoken));
        lend = new LendingPool(address(atoken), address(debtoken), payable(address(iweth)));
        ierc20AToken = IERC20(address(atoken));
        ierc20TokenWeth = IERC20(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a);
        ierc20TokenWeth = IERC20(address(iweth));
        bob = makeAddr("bob");
        deal(address(ierc20TokenWeth), bob, 2 ether);
        vm.deal(bob, 2 ether);
        deal(address(iweth), address(lend), 2 ether);


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