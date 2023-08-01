// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {aToken} from "../src/aToken.sol";
//import {WethGateWay} from "../src/WethGateWay.sol";
import {debtToken} from "../src/debtToken.sol";



contract LendingPool {

    IERC20 public ierc20Weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    aToken public atoken = new aToken();
    IERC20 public ierc20Atoken = IERC20(0x41C3c259514f88211c4CA2fd805A93F8F9A57504);
    

    function deposit(uint256 amount, address user) public {
        ierc20Weth.transferFrom(msg.sender, address(this), amount);
        atoken.mintAToken(user, amount);

    }

    function withdraw(uint256 amount, address user) public {
        ierc20Atoken.transferFrom(msg.sender, address(this), amount);
        //atoken.burnAToken(user, amount);
        //ierc20Weth.approve(msg.sender, amount);

    }


    
   

    

    receive() external payable {}
}