// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/debtToken.sol";

contract debtTokenTest is Test {

    debtToken public debt;
    address public alice;

    function setUp() public {
        debt = new debtToken();
        alice = makeAddr("alice");
    }

    function testMintDebtToken() public {
        uint256 supply = debt.totalSupply();
        debt.mintDebtToken(alice, 10 ether);
        assertEq(debt.balanceOf(alice), 10 ether);
        assertEq(debt.totalSupply(), supply + 10 ether);
    }

    function testBurndDebtToken() public {
        debt.mintDebtToken(alice, 10 ether);
        assertEq(debt.balanceOf(alice), 10 ether);
        uint256 supply = debt.totalSupply();
        debt.burnDebtToken(alice, 5 ether);
        assertEq(debt.balanceOf(alice), 5 ether);
        assertEq(debt.totalSupply(), supply - 5 ether);
        console.log(debt.addressDebtToken());
    }



}
    
