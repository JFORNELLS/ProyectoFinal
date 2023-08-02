// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AToken.sol";

contract ATokenTest is Test {

    AToken public atoken;
    address public alice;

    function setUp() public {
        atoken = new AToken();
        alice = makeAddr("alice");
    }

    function testMintAtiken() public {
        uint256 supply = atoken.totalSupply();
        atoken.mintAToken(alice, 10 ether);
        assertEq(atoken.balanceOf(alice), 10 ether);
        assertEq(atoken.totalSupply(), supply + 10 ether);
    }

    function testBurnDebToken() public {
        atoken.mintAToken(alice, 10 ether);
        assertEq(atoken.balanceOf(alice), 10 ether);
        uint256 supply = atoken.totalSupply();
        atoken.burnAToken(alice, 5 ether);
        assertEq(atoken.balanceOf(alice), 5 ether);
        assertEq(atoken.totalSupply(), supply - 5 ether);
    }
}
    
