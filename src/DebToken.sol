// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/solmate/src/tokens/ERC20.sol";
import {LendingPool, IAToken, IDebToken} from "../src/LendingPool.sol";

contract DebToken is ERC20 {
    event MintDebToken(address indexed to, uint256 amount);

    event BurnDebToken(address indexed account, uint256 amount);

    LendingPool public immutable lend;

    constructor(address payable _lend) ERC20("DebtToken", "DTN", 18) {
        lend = LendingPool(_lend);
    }

    modifier onlyLendingPool() {
        require(msg.sender == address(lend), "You are not autorized");
        _;
    }

    function mintDebToken(address to, uint256 amount) external onlyLendingPool {
        _mint(to, amount);

        emit MintDebToken(to, amount);
    }

    function burnDebToken(
        address account,
        uint256 amount
    ) external onlyLendingPool {
        _burn(account, amount);

        emit BurnDebToken(account, amount);
    }

    function transfer(address /*recipient*/, uint256 /*amount*/) public override returns (bool) {
        revert("Transfers of DebToken are not allowed");
    }

    function transferFrom(address /*sender*/, address /*recipient*/, uint256 /*amount*/) public override returns (bool) {
        revert("Transfers of DebToken are not allowed");
    }
}
