// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "src/WethGateWay.sol";
import "../src/AToken.sol";
import "../src/DebToken.sol";
import "../lib/solmate/src/tokens/WETH.sol";

interface IAToken {
    function mintAToken(address to, uint256 amount) external;
    function burnAToken(address account, uint256 amount) external;

}
interface IDebToken {
    function mintDebToken(address to, uint256 amount) external;
    function burnDebToken(address account, uint256 amount) external;
}

contract LendingPool {

    
    IAToken public immutable atoken;
    IDebToken public immutable debtoken;
    WETH public immutable tokenWeth;
    WethGateWay public immutable gateway;
    IERC20 public immutable iercAToken;
    IERC20 public immutable iercDebToken;
    IERC20 public immutable ierc20Weth;

    constructor(
        address _atoken, 
        address _debtoken, 
        address payable _tokenWeth, 
        address payable _gateway
        ) {
        atoken = IAToken(_atoken);
        debtoken = IDebToken(_debtoken);
        iercAToken = IERC20(_atoken);
        iercDebToken = IERC20(_debtoken);
        tokenWeth = WETH(_tokenWeth);
        ierc20Weth = IERC20(_tokenWeth);
        gateway = WethGateWay(_gateway);

        
    }
    

    function deposit(uint256 amount, address user) public {
        ierc20Weth.transferFrom(msg.sender, address(this), amount);
        IAToken(address(atoken)).mintAToken(user, amount);

    }

    function withdraw(uint256 amount, address user) public {
        if(msg.sender != address(gateway)) {
            ierc20Weth.transfer(msg.sender, amount);
        }
        iercAToken.transferFrom(msg.sender, address(this), amount);
        ierc20Weth.approve(msg.sender, amount);
        IAToken(address(atoken)).burnAToken(address(this), amount);

    }

    function borrow(uint256 amount, address user) public {
        if(msg.sender != address(gateway)) {
            ierc20Weth.transfer(msg.sender, amount);
        }
        ierc20Weth.approve(msg.sender, amount);
        IDebToken(address(debtoken)).mintDebToken(user, amount);
        
        
        
        
    }


    receive() external payable {}
}