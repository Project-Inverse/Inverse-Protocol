// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

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

interface OracleInterface{
    function latestAnswer() external view returns (int256);
}

contract XIVStaking is Ownable{
    
    using SafeMath for uint256;
    uint256 XIVPrice=1000000000000000000; //in wei, 18 decimals
    uint256 XIVPriceInUSDT=100000000; // in tokens with decimals 
    address XIVTokenContractAddress = 0xe667ee780908cAf92De34d7a749d9ACC1FB702C6; //XIV contract address
    address USDTContractAddress = 0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF; //USDT contract address
    mapping (address=>uint256) public tokensStaked; //amount of XIV staked by user
    address public ethOracleAddress=0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address oracleWrapperContractAddress = 0x8EAb4Ee4C4c4619Fe48C87248369E44380B9E2BF; //address of oracle wrapper from where the prices would be fetched
    
    struct DefiCoin{
        uint16 oracleType;
        bool status;
    }
    
    mapping(address=>DefiCoin) public defiCoinsForFlexibleMapping;
    address[] public allFlexibleContractAddressArray;
    mapping(address=>DefiCoin) public defiCoinsForFixedMapping;
    address[] public allFixedContractAddressArray;
    
    struct IndexCoin{
        uint16 oracleType;
        bool status;
        uint256 contributionPercentage; //10**4
    }
    mapping(address=>IndexCoin) public defiCoinsForFlexibleIndexMapping;
    address[] public allIndexFlexibleContractAddressArray;
    mapping(address=>IndexCoin) public defiCoinsForFixedIndexMapping;
    address[] public allIndexFixedContractAddressArray;
    
    uint256 betid;
    struct BetInfo{
        uint256 id;
        uint256 amount;
        address contractAddress;
        uint256 betType;
        uint256 betMarketCapAmount;
        uint256 timestamp;
        uint256 status; // 0->bet active, 1->bet won, 2->bet lost
    }
    BetInfo[] public betArray;
    mapping(uint256=>uint256) public findBetInArrayUsingBetIdMapping;
    
    function getXIVPrice(uint16 typeOfPrice) public view returns(uint256){
        //typeOfPrice =0 for eth and 1 for USDT
        //TODO fetch price from price oracle
        return typeOfPrice == 0 ? XIVPrice : XIVPriceInUSDT;
    }
    function setXIVPrice(uint256 price, uint16 typeOfPrice) public onlyOwner{
        //TODO to be removed when XIV price available in price oracle
        if(typeOfPrice == 0){
            XIVPrice = price;
        }else{
            XIVPriceInUSDT=price;
        }
        
    }
    function calculateAmtOfTokens(uint256 amount, uint256 typeOfPrice) public view returns(uint256){
        //returns tokens
        //0-ETH and 1 for USDT
        if(typeOfPrice == 0){
            return (10**Token(XIVTokenContractAddress).decimals()*(amount)).div(XIVPrice);
        }else{
            return (10**Token(XIVTokenContractAddress).decimals()*(amount)).div(XIVPriceInUSDT);
        }
    }
    function calculateETHUSDTTobeGiven(uint256 XIVtokensTobeExchanged, uint256 typeOfPrice) public view returns(uint256){
        //returns wei
        if(typeOfPrice == 0){
            return (XIVtokensTobeExchanged.mul(XIVPrice)).div(10**Token(XIVTokenContractAddress).decimals());
        }else{
            return (XIVtokensTobeExchanged.mul(XIVPriceInUSDT)).div(10**Token(XIVTokenContractAddress).decimals());
        }
        
    }
    function buyTokens(uint256 typeOfBuy, uint256 amount) public payable{
        //typeOfBuy ==0 ETH and 1 for USDT
        if(typeOfBuy == 0){
            Token tokenObj = Token(XIVTokenContractAddress);
            require(msg.value !=0, "Please send ETH to purchase XIV");
            require(tokenObj.balanceOf(address(this))> calculateAmtOfTokens(msg.value,0) , 
            "XIV Tokens not available");
            tokenObj.transfer(msg.sender,calculateAmtOfTokens(msg.value,0));
        }else{
            Token tokenObj = Token(XIVTokenContractAddress);
            Token usdtTokenObj = Token(USDTContractAddress);
            checkTokens(amount);
            require(tokenObj.balanceOf(address(this))> calculateAmtOfTokens(amount,1) , 
            "XIV Tokens not available");
            usdtTokenObj.transferFrom(msg.sender,address(this),amount);
            tokenObj.transfer(msg.sender,calculateAmtOfTokens(amount,1));
        }
    }
    function sellTokens(uint256 amountOfTokensToBeSold, uint256 typeOfCurrencyTobeReturned) public{
        //typeOfCurrencyTobeReturned  == 0 for ETH and 1 for USDT
        checkTokens(amountOfTokensToBeSold);
        Token tokenObj = Token(XIVTokenContractAddress);
        //ETH balance should be greater than  equal to required
        if(typeOfCurrencyTobeReturned == 0){
            require(address(this).balance >= calculateETHUSDTTobeGiven(amountOfTokensToBeSold,0),"The Contract does not have enough ethers."); 
            tokenObj.transferFrom(msg.sender,address(this),amountOfTokensToBeSold);
            payable(msg.sender).transfer(calculateETHUSDTTobeGiven(amountOfTokensToBeSold,0)); 
        }else{
            Token usdtTokenObj = Token(USDTContractAddress);
            require(usdtTokenObj.balanceOf(address(this)) >= calculateETHUSDTTobeGiven(amountOfTokensToBeSold,1),"The Contract does not have enough USDT tokens."); 
            tokenObj.transferFrom(msg.sender,address(this),amountOfTokensToBeSold);
            usdtTokenObj.transfer(msg.sender,calculateETHUSDTTobeGiven(amountOfTokensToBeSold,1));
        }
        
    }
    function stakeTokens(uint256 amount) public{
        checkTokens(amount);
        Token tokenObj = Token(XIVTokenContractAddress);
        tokenObj.transferFrom(msg.sender,address(this),amount);
        tokensStaked[msg.sender] = tokensStaked[msg.sender].add(amount);
    }
     function unStakeTokens(uint256 amount) public{
        require(tokensStaked[msg.sender]>=amount, "You don't have enough staking balance");
        Token tokenObj = Token(XIVTokenContractAddress);
        require(tokenObj.balanceOf(address(this)) >= amount, "You don't have enough XIV balance");
        //check if user has provided allowance
        tokenObj.transfer(msg.sender,amount);
        tokensStaked[msg.sender] = tokensStaked[msg.sender].sub(amount);
    }
    
    
    function betForDefi(uint256 amountOfXIV, uint256 typeOfBet, address _betContractAddress) public{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        checkTokens(amountOfXIV);
        if(typeOfBet==0){
            // defi fixed
            
        }else if(typeOfBet==1){
            //defi flexible
            
        }else if(typeOfBet==2){
            //index Fixed 
            defiCoinsForFixedIndexMapping[_betContractAddress];
            
        }else if(typeOfBet==3){
            //index flexible
            
        }
    }
    
    function addUpdateForDefiCoinFlexible(address _ContractAddress, uint16 _OracleType, bool _Status) public onlyOwner{
        // add update defi felxible coin
        DefiCoin memory dCoin=DefiCoin({
            oracleType:_OracleType,
            status:_Status
        });
        defiCoinsForFlexibleMapping[_ContractAddress]=dCoin;
        // check wheather contract exists in allFlexibleContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,allFlexibleContractAddressArray)){
            allFlexibleContractAddressArray.push(_ContractAddress);
        }
    }
    function addUpdateForDefiCoinFixed(address _ContractAddress, uint16 _OracleType, bool _Status) public onlyOwner{
        // add update defi fixed coin
        DefiCoin memory dCoin=DefiCoin({
            oracleType:_OracleType,
            status:_Status
        });
        defiCoinsForFixedMapping[_ContractAddress]=dCoin;
        // check wheather contract exists in allFixedContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,allFixedContractAddressArray)){
            allFixedContractAddressArray.push(_ContractAddress);
        }
    }
     function addUpdateForIndexCoinFlexible(address _ContractAddress, uint16 _OracleType, bool _Status, uint256 _contributionPercentage) public onlyOwner{
        // add update index fixed coin
       IndexCoin memory iCoin=IndexCoin({
            oracleType:_OracleType,
            status:_Status,
            contributionPercentage:_contributionPercentage
        });
        defiCoinsForFlexibleIndexMapping[_ContractAddress]=iCoin;
        // check wheather contract exists in allFixedContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,allIndexFlexibleContractAddressArray)){
            allIndexFlexibleContractAddressArray.push(_ContractAddress);
        }
    }
     function addUpdateForIndexCoinFixed(address _ContractAddress, uint16 _OracleType, 
                                            bool _Status, uint256 _contributionPercentage) public onlyOwner{
        // add update index fixed coin
        IndexCoin memory iCoin=IndexCoin({
            oracleType:_OracleType,
            status:_Status,
            contributionPercentage:_contributionPercentage
        });
        defiCoinsForFixedIndexMapping[_ContractAddress]=iCoin;
        // check wheather contract exists in allFixedContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,allIndexFixedContractAddressArray)){
            allIndexFixedContractAddressArray.push(_ContractAddress);
        }
    }
   
    function contractAvailableInArray(address _ContractAddress,address[] memory _contractArray) internal pure returns(bool){
        for(uint256 i=0;i<_contractArray.length;i++){
            if(_ContractAddress==_contractArray[i]){
                return true;
            }
        }
        return false;
    }  
    
    function checkTokens(uint256 amountOfXIV) internal view returns(bool){
         Token tokenObj = Token(XIVTokenContractAddress);
        //check if user has balance
        require(tokenObj.balanceOf(msg.sender) >= amountOfXIV, "You don't have enough XIV balance");
        //check if user has provided allowance
        require(tokenObj.allowance(msg.sender,address(this)) >= amountOfXIV, 
        "Please allow smart contract to spend on your behalf");
        return true;
    }
   
}
