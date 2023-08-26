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
    DebToken public immutable debtoken;
    LendingPool public immutable lend;
    IERC20 public immutable iercAToken;
    IERC20 public immutable iercWeth;
    IERC20 public immutable iercDebToken;
        

    constructor(
        address _atoken, 
        LendingPool _lend, 
        address _iweth,
        address _debtoken
        )  {
        atoken = AToken(_atoken);
        lend = _lend;
        iercAToken = IERC20(_atoken);
        iweth = IWETH(_iweth);
        iercWeth = IERC20(_iweth);
        debtoken = DebToken(_debtoken);
        iercDebToken = IERC20(_debtoken);
    }
    
    
    function depositETH() public payable {
        uint256 amount = msg.value;
        address user = msg.sender;

        iweth.deposit{value: amount}();
        iercWeth.approve(address(lend), amount);
        lend.deposit(amount, user);

    }

    function withdrawETH(uint256 amount) public payable {
        address user = msg.sender;
        iercAToken.transferFrom(msg.sender, address(this), amount);
        
        iercAToken.approve(address(lend), amount);
        lend.withdraw(amount, user);
        
        uint256 amountToWithdraw = amount + lend.calculateRewards(amount, user);
        iweth.withdraw(amountToWithdraw);
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Error Send ETH");
    } 

    function borrowETH(uint256 amount) public payable {
        address user = msg.sender;
        lend.borrow(amount, user);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error Send ETH");
    }

    function repayETH(uint256 amount) public payable {
        address user = msg.sender;
        lend.calculateInterest(amount, user);
        uint256 amountToRepay = lend.calculateInterest(amount, user);
        iweth.deposit{value: msg.value}();
        iercWeth.approve(address(lend), amountToRepay);
        iercDebToken.transferFrom(msg.sender, address(this), amount);
        lend.repay(amount, user);
        
          

    }

    
    receive() external payable {}
}