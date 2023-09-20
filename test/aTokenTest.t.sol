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
    event MintAToken(address indexed to, uint256 amount);

    event BurnAToken(address indexed account, uint256 amount);

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
        debtoken = new DebToken(payable(address(lend)));
        atoken = new AToken(payable(address(lend)));

        alice = makeAddr("alice");
    }

    function testMintAtoken() public {
        // If the caller is not LendingPool the function will revert.
        //vm.expectRevert();
        //atoken.mintAToken(alice, 10 ether);

        // If the caller is LendingPool the function works.
        vm.startPrank(address(lend));
        uint256 supply = atoken.totalSupply();

        // Ckeck the MintAToken event.
        vm.expectEmit();
        emit MintAToken(address(alice), 10 ether);

        // Mint to alice 10 ATokens.
        atoken.mintAToken(alice, 10 ether);

        // Check that alice has received 10 ATokens.
        assertEq(atoken.balanceOf(alice), 10 ether);

        // Check that total supply has increased 10 ATokens.
        assertEq(atoken.totalSupply(), supply + 10 ether);
    }

    function testBurnAToken() public {
        //If the caller is not LendingPool the function will revert.
        vm.expectRevert();
        atoken.burnAToken(alice, 5 ether);

        // If the caller is LendingPool the function works.
        vm.startPrank(address(lend));
        atoken.mintAToken(alice, 10 ether);
        uint256 supply = atoken.totalSupply();

        // Ckeck the MintAToken event.
        vm.expectEmit();
        emit BurnAToken(address(alice), 5 ether);

        // Burn 5 ATokens from alice's balance.
        atoken.burnAToken(alice, 5 ether);

        // Check that Alice's balance has decreased by 5 ATokens.
        assertEq(atoken.balanceOf(alice), 5 ether);

        // Check that total supply has decreased by 5 ATokens.
        assertEq(atoken.totalSupply(), supply - 5 ether);
    }
}
