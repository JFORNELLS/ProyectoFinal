// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "../lib/solmate/src/tokens/ERC20.sol";
contract aToken is ERC20 {


    constructor() ERC20("aToken", "ATN", 18) {}

    function mintAToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnAToken(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
    
