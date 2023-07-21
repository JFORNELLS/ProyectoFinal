// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "../lib/solmate/src/tokens/ERC20.sol";
contract debtToken is ERC20 {


    constructor() ERC20("debtToken", "DTN", 18) {}

    function mintDebtToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnDebtToken(address account, uint256 amount) public {
        _burn(account, amount);
    }
}