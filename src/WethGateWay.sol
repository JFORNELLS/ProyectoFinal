// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "src/LendingPool.sol";
import "../lib/forge-std/src/interfaces/IERC20.sol";
//import "../openzeppelin-contracts/contracts/token/ERC20/utils/safeERC20.sol";
//import "../openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "src/aToken.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
interface ILend {
    function deposit(uint256 amount) external;
}

interface ITtoken {
    function mintAToken(address to, uint256 amount) external;
}





contract WethGateWay {

    IWETH public immutable iweth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public immutable tokenWeth = (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    LendingPool public  lend = new LendingPool();
    aToken public atoken = new aToken();

   
    function depositETH(uint256 amount) external payable {
        iweth.deposit{value: msg.value}();
        IERC20(tokenWeth).approve(address(lend), amount);
        ILend(address(lend)).deposit(amount);
    }
   
    

    function withdrawETH(uint256 amount) external {
        IERC20(address(atoken)).transferFrom(address(this), address(lend), amount);

        //iweth.withdraw(amount);

    }

    function getATokenBalance(address _address) public view returns (uint256) {
        return atoken.balanceOf(_address);
    }

  

    
    receive() external payable {}
}