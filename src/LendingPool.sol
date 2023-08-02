// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {AToken} from "../src/AToken.sol";
import {debtToken} from "../src/debtToken.sol";

interface IAToken {
    function mintAToken(address to, uint256 amount) external;
    function burnAToken(address account, uint256 amount) external;
    function balancesOf(address account) external view returns (uint256);

}

contract LendingPool {

    IERC20 public ierc20Weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IAToken public atoken;
    IERC20 public ierc20AToken = IERC20(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f);

    constructor(IAToken _atoken) {
        atoken = _atoken;
        

        
    }
    

    function deposit(uint256 amount, address user) public {
        ierc20Weth.transferFrom(msg.sender, address(this), amount);
        IAToken(address(atoken)).mintAToken(user, amount);

    }

    function withdraw(uint256 amount, address user) public {
        ierc20AToken.transferFrom(msg.sender, address(this), amount);
        IAToken(address(atoken)).burnAToken(user, amount);
        ierc20Weth.approve(msg.sender, amount);

    }


    
   

    

    receive() external payable {}
}