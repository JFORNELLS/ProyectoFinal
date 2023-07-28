// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {LendingPool} from "src/LendingPool.sol";
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {aToken} from "src/aToken.sol";
import {debtToken} from "src/debtToken.sol";
import {Dates} from "src/Data.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}


contract WethGateWay {



    IWETH public immutable iweth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public immutable tokenWeth = (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    LendingPool public  lend = new LendingPool();
    aToken public atoken = new aToken();
    debtToken public debttoken = new debtToken();
    Dates public update = new Dates();

    // Function to deposit ETH.
    function depositETH(uint256 amount) external payable {
        update.addDates(amount);
        iweth.deposit{value: msg.value}(); 
        IERC20(tokenWeth).approve(address(lend), amount); 
        lend.deposit(amount); 
    }
   
    // Hola! el problema ve quan vull enviar els atoken. error "Arithmetic over/underflow"
    // En el testDepositETH hi ha l'approve per enviar els atoken d'Alice.

    function withdrawETH(uint256 amount) external {
        IERC20(address(atoken)).transferFrom(msg.sender, address(lend), amount); 
        lend.withdraw(amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error send ETH");
        
    }

    function borrowETH(uint256 amount) external payable {
        lend.borrow(amount);
        iweth.withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Error sen ETH");
        IERC20(address(debttoken)).approve(msg.sender, amount);
        //IERC20(address(debttoken)).transferFrom(address(this), msg.sender, amount);

    }



    function getATokenBalance(address _address) public view returns (uint256) {
        return atoken.balanceOf(_address);
    }

  

    
    receive() external payable {}
}