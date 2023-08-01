// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
contract debtToken is ERC20 {

    address public addressDebtToken;

    constructor() ERC20("debtToken", "DTN", 18) {
        addressDebtToken = address(this);
    }

    function mintDebtToken(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burnDebtToken(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function approveToken(address spender, uint256 amount) public {
        approve(spender, amount);
    }

    function transferFromToken(address from, address to, uint256 amount) public {
        transferFrom(from, to,amount);
    }
}