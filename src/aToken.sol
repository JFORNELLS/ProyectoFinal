// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
contract aToken is ERC20 {

    address public addressAToken;

    constructor() ERC20("aToken", "ATN", 18) {
        addressAToken = address(this);
    }

    function mintAToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnAToken(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferFromAT(address from, address to, uint256 amount) public {
        transferFrom(from, to, amount);
    }

    function approveAT(address spender, uint256 amount) public {
        approve(spender, amount);
    }
  
}
    
