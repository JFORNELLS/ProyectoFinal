// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DebToken.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";
import {WethGateWay} from "../src/WethGateWay.sol";
import "../lib/solmate/src/tokens/WETH.sol";
import "../src/AToken.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";

contract DebTokenTest is Test {
    

    event MintDebToken(
        address indexed to,
        uint256 amount
    );

    event BurnDebToken(
        address indexed account,
        uint256 amount
    );


    LendingPool public lend;
    WETH public weth;
    DebToken public debtoken;
    WethGateWay public gateway;
    AToken public atoken;
    address public alice;
    address public owner;


    function setUp() public {

        lend = new LendingPool(
            address(atoken), 
            address(debtoken), 
            payable(address(weth)), 
            payable(address(gateway)),
            address(owner)
            );


        gateway = new WethGateWay(
            address(atoken), 
            lend, 
            address(weth), 
            address(debtoken)
            );    

        weth = new WETH();
        atoken = new AToken(payable(address(lend)));
        debtoken = new DebToken(payable(address(lend)));

        alice = makeAddr("alice");


    }

    function testMintDebtToken() public {
        // If the caller is not LendingPool the function will revert.
        vm.expectRevert();
        debtoken.mintDebToken(alice, 10 ether);

        // If the caller is LendingPool the function works.
        vm.startPrank(address(lend));
        uint256 supply = debtoken.totalSupply();

        // Ckeck the DebtAToken event.
        vm.expectEmit(true, false, false, true, address(debtoken));
        emit MintDebToken(address(alice), 10 ether);

        // Mint to alice 10 DebTokens.
        debtoken.mintDebToken(alice, 10 ether);

        // Check that alice has received 10 DebTokens.
        assertEq(debtoken.balanceOf(alice), 10 ether);

        // Check that total supply has increased 10 DebTokens.
        assertEq(debtoken.totalSupply(), supply + 10 ether);
    }

    function testBurndDebtToken() public {
        //If the caller is not LendingPool the function will revert.
        vm.expectRevert();
        debtoken.burnDebToken(alice, 5 ether);

        // If the caller is LendingPool the function works.
        vm.startPrank(address(lend));
        debtoken.mintDebToken(alice, 10 ether);
        assertEq(debtoken.balanceOf(alice), 10 ether);
        uint256 supply = debtoken.totalSupply();

        // Ckeck the MintAToken event.
        vm.expectEmit(true, false, false, true, address(debtoken));
        emit BurnDebToken(address(alice), 5 ether);

        // Burn 5 DebTokens from alice's balance.
        debtoken.burnDebToken(alice, 5 ether);

        // Check that Alice's balance has decreased by 5 DebTokens.
        assertEq(debtoken.balanceOf(alice), 5 ether);

        // Check that total supply has decreased by 5 DebTokens.
        assertEq(debtoken.totalSupply(), supply - 5 ether);
    }
}
    
