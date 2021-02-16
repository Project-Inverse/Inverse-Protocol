// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";


contract XIVMain is Ownable{
    
    using SafeMath for uint256;
    uint256 XIVPrice=1000000000000000000; //in wei, 18 decimals
    uint256 XIVPriceInUSDT=100000000; // in tokens with decimals 
    
    address public databaseContractAddress=0x752e144BF110207d925691F78a84b07437ff5544;
    
    XIVDatabaseLib.IndexCoin[] tempObjectArray;
    
     function getXIVPrice(uint16 typeOfPrice) external view returns(uint256){
        //typeOfPrice =0 for eth and 1 for USDT
        //TODO fetch price from price oracle
        return typeOfPrice == 0 ? XIVPrice : XIVPriceInUSDT;
    }
    function setXIVPrice(uint256 price, uint16 typeOfPrice) external onlyOwner{
        //TODO to be removed when XIV price available in price oracle
        if(typeOfPrice == 0){
            XIVPrice = price;
        }else{
            XIVPriceInUSDT=price;
        }
    }
    
    function calculateAmtOfTokens(uint256 amount, uint16 typeOfPrice) public view returns(uint256){
        //returns tokens
        //0-ETH and 1 for USDT
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfPrice == 0){
            return (10**Token(dContract.getXIVTokenContractAddress()).decimals()*(amount)).div(XIVPrice);
        }else{
            return (10**Token(dContract.getXIVTokenContractAddress()).decimals()*(amount)).div(XIVPriceInUSDT);
        }
    }
    function calculateETHUSDTTobeGiven(uint256 XIVtokensTobeExchanged, uint16 typeOfPrice) public view returns(uint256){
        //returns wei
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfPrice == 0){
            return (XIVtokensTobeExchanged.mul(XIVPrice)).div(10**Token(dContract.getXIVTokenContractAddress()).decimals());
        }else{
            return (XIVtokensTobeExchanged.mul(XIVPriceInUSDT)).div(10**Token(dContract.getXIVTokenContractAddress()).decimals());
        }
        
    }
    function buyTokens(uint16 typeOfBuy, uint256 amount) external payable{
        //typeOfBuy ==0 ETH and 1 for USDT
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfBuy == 0){
            require(msg.value !=0, "Please send ETH to purchase XIV");
            dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,calculateAmtOfTokens(msg.value,0));
            payable(databaseContractAddress).transfer(msg.value);
        }else{
            dContract.transferFromTokens(dContract.getUSDTContractAddress(),msg.sender,databaseContractAddress,amount);
            dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,calculateAmtOfTokens(amount,1));
        }
    }
    function sellTokens(uint256 amountOfTokensToBeSold, uint256 typeOfCurrencyTobeReturned) external{
        //typeOfCurrencyTobeReturned  == 0 for ETH and 1 for USDT
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfCurrencyTobeReturned == 0){ 
            dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amountOfTokensToBeSold);
            dContract.transferETH(payable(msg.sender),calculateETHUSDTTobeGiven(amountOfTokensToBeSold,0));
        }else{
            dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amountOfTokensToBeSold);
            dContract.transferTokens(dContract.getUSDTContractAddress(),msg.sender,calculateETHUSDTTobeGiven(amountOfTokensToBeSold,1));
        }
        
    }
    function stakeTokens(uint256 amount) external{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        Token tokenObj = Token(dContract.getXIVTokenContractAddress());
        //check if user has balance
        require(tokenObj.balanceOf(msg.sender) >= amount, "You don't have enough XIV balance");
        //check if user has provided allowance
        require(tokenObj.allowance(msg.sender,databaseContractAddress) >= amount, 
        "Please allow smart contract to spend on your behalf");
        uint256 adminAmount=((dContract.getAdminStakingFee().mul(amount)).div(10**4));
        uint256 userAmount=amount.sub(adminAmount);
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,dContract.getAdminAddress(),adminAmount);
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,userAmount);
        dContract.updateTokensStaked(msg.sender,dContract.getTokensStaked(msg.sender).add(userAmount));
        dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().add(userAmount));
        dContract.saveStakedAddress(true, msg.sender);
    }
     function unStakeTokens(uint256 amount) external{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        require(dContract.getTokensStaked(msg.sender)>=amount, "You don't have enough staking balance");
        dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,amount);
        dContract.updateTokensStaked(msg.sender,dContract.getTokensStaked(msg.sender).sub(amount));
        dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(amount));
        dContract.saveStakedAddress(false, msg.sender);
    }
    
    function updateDatabaseAddress(address _databaseContractAddress) external onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
}
