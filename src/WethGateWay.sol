// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "src/AToken.sol";
import "src/DebToken.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}



contract WethGateWay {
    AToken public atoken;
    LendingPool public lend;
    IERC20 public ierc20AToken;
    
    IWETH public immutable iweth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public iercWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    

    constructor(address _atoken, LendingPool _lend)  {
        atoken = AToken(_atoken);
        lend = _lend;
        ierc20AToken = IERC20(_atoken);
    }
    
    
    function depositETH() public payable {
        uint256 amount = msg.value;
        iweth.deposit{value: amount}();
        address user = msg.sender;
        iercWeth.approve(address(lend), amount);
        lend.deposit(amount, user);

    }

    function withdrawETH(uint256 amount) public payable {
        ierc20AToken.transferFrom(msg.sender, address(this), amount);
        ierc20AToken.approve(address(lend), amount);
        address user = msg.sender;
        lend.withdraw(amount, user);
        iercWeth.transferFrom(address(lend), address(this), amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error Send ETH");
    }

    function borrowETH(uint256 amount) public {
        address user = msg.sender;
        lend.borrow(amount, user);
        //iercWeth.transferFrom(address(lend), address(this), amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error Send ETH");
    }

    
    receive() external payable {}
}