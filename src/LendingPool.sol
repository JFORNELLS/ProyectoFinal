// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "../src/aToken.sol";
//import "../openzeppelin-contracts/contracts/token/ERC20/utils/safeERC20.sol";
//import "../openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface IaToken {
    function mintAToken(address to, uint256 amount) external;
}




contract LendingPool {

    error IncorrectAmount();

    address public tokenWeth = (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    aToken public atoken = new aToken();
    mapping(address => uint256) public balanceWeth;

   function deposit(uint256 amount) external  {
        balanceWeth[msg.sender] += amount;
        IERC20(tokenWeth).transferFrom(msg.sender, address(this), amount);

        IaToken(address(atoken)).mintAToken(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        IERC20(address(atoken)).transferFrom(msg.sender, address(this), amount);
        


    }

    function getATokenBalance(address _address) public view returns (uint256) {
        return atoken.balanceOf(_address);
    }

    

    receive() external payable {}
}