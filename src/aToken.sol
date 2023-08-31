// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";
contract AToken is ERC20 {

    LendingPool public lend;

    modifier onlyLendingPool {
        require(msg.sender == address(lend), "You are not autorized");
        _;
    }

    constructor(address payable _lend) ERC20("AToken", "ATN", 18) {
        lend = LendingPool(_lend);
    }


    function mintAToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnAToken(address account, uint256 amount) public {
        _burn(account, amount);
    }

    
}
    
