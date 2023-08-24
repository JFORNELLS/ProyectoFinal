// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
contract AToken is ERC20 {

    constructor() ERC20("AToken", "ATN", 18) {}


    function mintAToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnAToken(address account, uint256 amount) public {
        _burn(account, amount);
    }

    
}
    
