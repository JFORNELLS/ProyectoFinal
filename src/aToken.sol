// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";

contract AToken is ERC20 {
    event MintAToken(address indexed to, uint256 amount);

    event BurnAToken(address indexed account, uint256 amount);

    LendingPool public immutable lend;

    constructor(address payable _lend) ERC20("AToken", "ATN", 18) {
        lend = LendingPool(_lend);
    }

    modifier onlyLendingPool() {
        require(msg.sender == address(lend), "You are not autorized");
        _;
    }

    function mintAToken(address to, uint256 amount) external onlyLendingPool {
        _mint(to, amount);

        emit MintAToken(to, amount);
    }

    function burnAToken(
        address account,
        uint256 amount
    ) external onlyLendingPool {
        _burn(account, amount);

        emit BurnAToken(account, amount);
    }
}
