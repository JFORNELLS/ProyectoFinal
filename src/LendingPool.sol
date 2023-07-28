// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {aToken} from "../src/aToken.sol";
import {debtToken} from "../src/debtToken.sol";



contract LendingPool {


    address public tokenWeth = (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    aToken public atoken = new aToken();
    debtToken public debttoken = new debtToken();
    mapping(address => uint256) public balanceWeth;

   function deposit(uint256 amount) external  {
        balanceWeth[msg.sender] += amount;
        IERC20(tokenWeth).transferFrom(msg.sender, address(this), amount);

        atoken.mintAToken(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        IERC20(tokenWeth).approve(msg.sender, amount);
        IERC20(tokenWeth).transferFrom(address(this), msg.sender, amount);
        
    }


    function borrow(uint256 amount) external {
        IERC20(address(tokenWeth)).approve(msg.sender, amount);
        IERC20(address(tokenWeth)).transferFrom(address(this), msg.sender, amount);
        debttoken.mintDebtToken(msg.sender, amount);

        
    }

    function getATokenBalance(address _address) public view returns (uint256) {
        return atoken.balanceOf(_address);
    }

    

    receive() external payable {}
}