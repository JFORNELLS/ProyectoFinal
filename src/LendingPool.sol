// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";

interface IAToken {
    function mintAToken(address to, uint256 amount) external;
    function burnAToken(address account, uint256 amount) external;

}
interface IDebToken {
    function mintDebToken(address to, uint256 amount) external;
    function burnDebToken(address account, uint256 amount) external;
}

contract LendingPool {

    
    IAToken public atoken;
    IDebToken public debtoken;
    IERC20 public ierc20AToken = IERC20(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f);
    IERC20 public ierc20Weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(IAToken _atoken, IDebToken _debtoken) {
        atoken = _atoken;
        debtoken = _debtoken;

        
    }
    

    function deposit(uint256 amount, address user) public {
        ierc20Weth.transferFrom(msg.sender, address(this), amount);
        IAToken(address(atoken)).mintAToken(user, amount);

    }

    function withdraw(uint256 amount, address user) public {
        ierc20AToken.transferFrom(msg.sender, address(this), amount);
        IAToken(address(atoken)).burnAToken(address(this), amount);
        ierc20Weth.approve(msg.sender, amount);

    }

    function borrow(uint256 amount, address user) public {
        ierc20Weth.approve(msg.sender, amount);
        ierc20Weth.transferFrom(address(this), msg.sender, amount);
        IDebToken(address(debtoken)).mintDebToken(user, amount);
        
    }


    
   

    

    receive() external payable {}
}