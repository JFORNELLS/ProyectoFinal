// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
contract aToken is ERC20 {


    constructor() ERC20("aToken", "ATN", 18) {
        _mint(msg.sender, 10000 ether);
    }

    function mintAToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnAToken(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferFromAToken(address from, address to, uint256 amount) public {
          transferFrom(from, to,amount);
    } 
}
    
