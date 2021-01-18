// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.0;
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
interface Token{
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function burnTokens(address who,uint256 _value) external;
}
contract XIVStaking{
    using SafeMath for uint256;
    uint256 XIVPrice; //in wei, 18 decimals
    address owner; //contract owner
    address XIVTokenContractAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138; //XIV contract address
    constructor(){
        owner = msg.sender;
    }
    function getXIVPrice() public view returns(uint256){
        return XIVPrice;
    }
    function setXIVPrice(uint256 price) public onlyOwner{
       XIVPrice = price; 
    }
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function calculateAmtOfTokens(uint256 amountInWei) public view returns(uint256){
        //returns tokens
       return (10**Token(XIVTokenContractAddress).decimals()*(amountInWei)).div(XIVPrice);
    }
    function calculateETHTobeGiven(uint256 XIVtokensTobeExchanged) public view returns(uint256){
        //returns wei
        return (XIVtokensTobeExchanged.mul(XIVPrice)).div(10**Token(XIVTokenContractAddress).decimals());
    }
    function buyTokens() public payable{
        Token tokenObj = Token(XIVTokenContractAddress);
        require(msg.value !=0, "Please send ETH to purchase XIV");
        require(tokenObj.balanceOf(address(this))> calculateAmtOfTokens(msg.value) , 
        "XIV Tokens not available");
        tokenObj.transfer(msg.sender,calculateAmtOfTokens(msg.value));
        
    }
    function sellTokens(uint256 amountOfTokensToBeSold) public{
        Token tokenObj = Token(XIVTokenContractAddress);
        //check if user has balance
        require(tokenObj.balanceOf(msg.sender) >= amountOfTokensToBeSold, "You dont have enough XIV balance");
        //check if user has provided allowance
        require(tokenObj.allowance(msg.sender,address(this)) >= amountOfTokensToBeSold, 
        "Please allow smart contract to spend on your behalf");
        //ETH balance should be greater than  equal to required
        require(address(this).balance <= calculateETHTobeGiven(amountOfTokensToBeSold)); 
        tokenObj.transferFrom(msg.sender,address(this),amountOfTokensToBeSold);
        payable(msg.sender).transfer(calculateETHTobeGiven(amountOfTokensToBeSold));
    }
}