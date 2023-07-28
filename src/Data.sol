// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Dates {

   
    enum State {
        SUPPLY,
        BORROW
    }

    struct Data {
        address supplier;
        uint256 deposit;
        uint256 time;
        State state;
    }

    mapping(address => Data) public dates;

    function addDates(uint256 amount) external {
        Data storage data = dates[msg.sender];
        data.supplier = msg.sender;
        data.deposit = amount;
        data.time = block.timestamp;
        
    }

}