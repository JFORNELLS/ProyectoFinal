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

    enum State {
        SUPPLY,
        BORROW
    }

    struct Data {
        address supplier;
        uint256 deposit;
        uint256 timeSupply;
        uint256 borrowed;
        uint256 timeBorrow;
        uint256 debTokenMinted;
        State state;
    }


    IAToken public immutable atoken;
    IDebToken public immutable debtoken;
    WETH public immutable tokenWeth;
    WethGateWay public immutable gateway;
    IERC20 public immutable iercAToken;
    IERC20 public immutable iercDebToken;
    IERC20 public immutable iercWeth;

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
        iercWeth = IERC20(_tokenWeth);
        gateway = WethGateWay(_gateway);

    }

    
    uint256 public totalSupplies;
    uint256 public balanceSupply;
    uint256 public totalBorrows;
    uint256 public balanceBorrow;

    mapping(address => Data) public supplies;
    mapping(address => Data) public borrows;

    function deposit(uint256 amount, address user) public {
        Data storage data = supplies[user];
        data.supplier = user;
        data.deposit = amount;
        data.timeSupply = block.timestamp;
        data.state = State.SUPPLY;

        balanceSupply += amount;
        totalSupplies++;

        iercWeth.transferFrom(msg.sender, address(this), amount);
        IAToken(address(atoken)).mintAToken(user, amount);

    }

    function withdraw(uint256 amount, address user) public {
        iercAToken.transferFrom(msg.sender, address(this), amount);
        if(msg.sender != address(gateway)) {
            iercWeth.transfer(msg.sender, amount);
        }
        
        iercWeth.approve(msg.sender, amount);
        IAToken(address(atoken)).burnAToken(address(this), amount);

    }

    function borrow(uint256 amount, address user) public {
        Data storage data = supplies[user];
        data.borrowed = amount;
        data.timeBorrow = 365 days;
        data.debTokenMinted = amount;
        data.state = State.BORROW;

        balanceBorrow += amount;
        totalBorrows++;

        if(msg.sender != address(gateway)) {
            iercWeth.transfer(msg.sender, amount);
        }
        iercWeth.approve(msg.sender, amount);
        IDebToken(address(debtoken)).mintDebToken(user, amount);
            
    }

    function repay(uint256 amount, address user) public {
        iercWeth.transferFrom(msg.sender, address(this), amount);
        uint256 debTokenMinted = debTokenMinted(user);
        iercDebToken.transferFrom(msg.sender, address(this), debTokenMinted);
        IDebToken(address(debtoken)).burnDebToken(address(this), debTokenMinted);

    }


    function amountToRepay(address user) public  returns (uint256) {
        Data memory data = supplies[user];
        uint256 amount = data.borrowed;
        uint256 time = data.timeBorrow;
        uint256 interest = (amount * 10) / 100;
        uint256 amountRepay = amount + interest;
        
        return amountRepay;
    }

    function debTokenMinted(address user) public view returns (uint256) {
        return supplies[user].debTokenMinted;
    }


        
  

    


    receive() external payable {}
}