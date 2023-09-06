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
        address user = msg.sender;

        iweth.deposit{value: msg.value}();
        iercWeth.approve(address(lend), msg.value);
        lend.deposit(user, msg.value);

    }


    function withdrawETH(uint256 amount) public payable {
        address user = msg.sender;

        require(
            iercAToken.transferFrom(msg.sender, address(this), amount),
            "Error Sending ATokens"
        );
        
        iercAToken.approve(address(lend), amount);
        lend.withdraw(user, amount);
        
        uint256 amountToWithdraw = amount + lend.calculateRewards(amount, user);
        iweth.withdraw(amountToWithdraw);
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Error sending ETH to user");

    } 


    function borrowETH(uint256 amount) public payable {
        address user = msg.sender;
        lend.borrow(user, amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error sending ETH to user");

    }


    function repayETH(uint256 amount) public payable {
        address user = msg.sender;

        uint256 interest = lend.calculateInterest(amount, user);
        uint256 amountToRepay = amount + interest;

        uint256 refundAmount = msg.value - amountToRepay;
        if (refundAmount > 0) {
            iweth.deposit{value: refundAmount}();
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            require(success, "Error sending excess ETH back to the user");
        } 

        iweth.deposit{value: amountToRepay}();
        iercWeth.approve(address(lend), amountToRepay);

        require(
            iercDebToken.transferFrom(msg.sender, address(this), amount),
            "Error Sending DebTokens"
        );
        
        lend.repay(user, amount);
        
       
        
    }
        
          

    

    
    receive() external payable {}
}