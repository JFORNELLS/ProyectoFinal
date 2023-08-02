// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DebToken.sol";

contract DebTokenTest is Test {

    DebToken public debt;
    address public alice;

    function setUp() public {
        debt = new DebToken();
        alice = makeAddr("alice");
    }

    function testMintDebtToken() public {
        uint256 supply = debt.totalSupply();
        debt.mintDebToken(alice, 10 ether);
        assertEq(debt.balanceOf(alice), 10 ether);
        assertEq(debt.totalSupply(), supply + 10 ether);
    }

    function testBurndDebtToken() public {
        debt.mintDebToken(alice, 10 ether);
        assertEq(debt.balanceOf(alice), 10 ether);
        uint256 supply = debt.totalSupply();
        debt.burnDebToken(alice, 5 ether);
        assertEq(debt.balanceOf(alice), 5 ether);
        assertEq(debt.totalSupply(), supply - 5 ether);
    }
}
    
