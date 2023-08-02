// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
contract DebToken is ERC20 {


    constructor() ERC20("DebtToken", "DTN", 18) {}

    function mintDebToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnDebToken(address account, uint256 amount) public {
        _burn(account, amount);
    }

}   