// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AToken.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";
import {WethGateWay} from "../src/WethGateWay.sol";
import "../lib/solmate/src/tokens/WETH.sol";
import "../src/DebToken.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";


contract ATokenTest is Test {

    LendingPool public lend;
    WETH public weth;
    DebToken public debtoken;
    WethGateWay public gateway;
    AToken public atoken;
    address public alice;

    function setUp() public {
        
        
        lend = new LendingPool(
            address(atoken), 
            address(debtoken), 
            payable(address(weth)), 
            payable(address(gateway))
            );

        gateway = new WethGateWay(
            address(atoken), 
            lend, 
            address(weth), 
            address(debtoken)
            );    
        weth = new WETH();
        debtoken = new DebToken();
        atoken = new AToken(payable(address(lend)));

        alice = makeAddr("alice");

        deal(address(weth), address(this), 2 ether);
    }

    function testMintAtoken() public {
        //If the caller is not LendingPool the function will revert.
        //vm.expectRevert();
        //atoken.mintAToken(alice, 10 ether);

        vm.startPrank(address(lend));
        uint256 supply = atoken.totalSupply();
        atoken.mintAToken(alice, 10 ether);
        assertEq(atoken.balanceOf(alice), 10 ether);
        assertEq(atoken.totalSupply(), supply + 10 ether);
    }

    function testBurnAToken() public {
        //If the caller is not LendingPool the function will revert.
        vm.expectRevert();
        atoken.burnAToken(alice, 5 ether);

        vm.startPrank(address(lend));
        atoken.mintAToken(alice, 10 ether);
        assertEq(atoken.balanceOf(alice), 10 ether);
        uint256 supply = atoken.totalSupply();
        atoken.burnAToken(alice, 5 ether);
        assertEq(atoken.balanceOf(alice), 5 ether);
        assertEq(atoken.totalSupply(), supply - 5 ether);
    }
    
    
}
    
