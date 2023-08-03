// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
import "src/AToken.sol";
import "src/DebToken.sol";
import "../lib/solmate/src/tokens/WETH.sol";
interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}



contract WethGateWay {


    IWETH public immutable iweth;
    AToken public immutable atoken;
    LendingPool public immutable lend;
    IERC20 public immutable iercAToken;
    IERC20 public immutable iercWeth;
        

    constructor(
        address _atoken, 
        LendingPool _lend, 
        address _iweth
        )  {
        atoken = AToken(_atoken);
        lend = _lend;
        iercAToken = IERC20(_atoken);
        iweth = IWETH(_iweth);
        iercWeth = IERC20(_iweth);
    }
    
    
    function depositETH() public payable {
        uint256 amount = msg.value;
        iweth.deposit{value: amount}();
        address user = msg.sender;
        iercWeth.approve(address(lend), amount);
        lend.deposit(amount, user);

    }

    function withdrawETH(uint256 amount) public payable {
        iercAToken.transferFrom(msg.sender, address(this), amount);
        iercAToken.approve(address(lend), amount);
        address user = msg.sender;
        lend.withdraw(amount, user);
        iercWeth.transferFrom(address(lend), address(this), amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error Send ETH");
    }

    function borrowETH(uint256 amount) public payable {
        address user = msg.sender;
        lend.borrow(amount, user);
        iercWeth.transferFrom(address(lend), address(this), amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error Send ETH");
    }

    
    receive() external payable {}
}