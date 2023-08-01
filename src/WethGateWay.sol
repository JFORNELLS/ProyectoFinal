// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {LendingPool} from "src/LendingPool.sol";
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {aToken} from "src/aToken.sol";
import {debtToken} from "src/debtToken.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}




contract WethGateWay {

    IWETH public immutable iweth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public weth = (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public iercWeth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public ierc20Atoken = IERC20(0x41C3c259514f88211c4CA2fd805A93F8F9A57504);
    LendingPool public lend = new LendingPool();
    
    function depositETH() public payable {
        uint256 amount = msg.value;
        iweth.deposit{value: amount}();
        address user = msg.sender;
        iercWeth.approve(address(lend), amount);
        lend.deposit(amount, user);

    }

    function withdrawETH(uint256 amount) public payable {
        ierc20Atoken.transferFrom(msg.sender, address(this), amount);
        ierc20Atoken.approve(address(lend), amount);
        address user = msg.sender;
        lend.withdraw(amount, user);
        iercWeth.transferFrom(address(lend), address(this), amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error Send ETH");
    }

    


   

  
    

    
   
    
    

  

    receive() external payable {}
}