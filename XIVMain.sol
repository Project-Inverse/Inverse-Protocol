// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";


contract XIVMain is Ownable{
    
    using SafeMath for uint256;
    uint256 secondsInADay=86400;
    // uint256 sevenDays= 7 days;
    uint256 sevenDays= 300;
    uint256 XIVPrice=1000000000000000000; //in wei, 18 decimals
    uint256 XIVPriceInUSDT=100000000; // in tokens with decimals 
    address XIVTokenContractAddress = 0xe667ee780908cAf92De34d7a749d9ACC1FB702C6; //XIV contract address
    address USDTContractAddress = 0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF; //USDT contract address
    address oracleWrapperContractAddress = 0xf2aE63Ba2FD4C4Dfd27D4414bc78f4762dE54024; //address of oracle wrapper from where the prices would be fetched
    
    address public databaseContractAddress;
    
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
    
    function calculateAmtOfTokens(uint256 amount, uint16 typeOfPrice) public view returns(uint256){
        //returns tokens
        //0-ETH and 1 for USDT
        if(typeOfPrice == 0){
            return (10**Token(XIVTokenContractAddress).decimals()*(amount)).div(XIVPrice);
        }else{
            return (10**Token(XIVTokenContractAddress).decimals()*(amount)).div(XIVPriceInUSDT);
        }
    }
    function calculateETHUSDTTobeGiven(uint256 XIVtokensTobeExchanged, uint16 typeOfPrice) public view returns(uint256){
        //returns wei
        if(typeOfPrice == 0){
            return (XIVtokensTobeExchanged.mul(XIVPrice)).div(10**Token(XIVTokenContractAddress).decimals());
        }else{
            return (XIVtokensTobeExchanged.mul(XIVPriceInUSDT)).div(10**Token(XIVTokenContractAddress).decimals());
        }
        
    }
    function buyTokens(uint16 typeOfBuy, uint256 amount) public payable{
        //typeOfBuy ==0 ETH and 1 for USDT
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfBuy == 0){
            require(msg.value !=0, "Please send ETH to purchase XIV");
            dContract.transferTokens(XIVTokenContractAddress,msg.sender,calculateAmtOfTokens(msg.value,0));
        }else{
            dContract.transferFromTokens(USDTContractAddress,msg.sender,databaseContractAddress,amount);
            dContract.transferTokens(XIVTokenContractAddress,msg.sender,calculateAmtOfTokens(amount,1));
        }
    }
    function sellTokens(uint256 amountOfTokensToBeSold, uint256 typeOfCurrencyTobeReturned) public{
        //typeOfCurrencyTobeReturned  == 0 for ETH and 1 for USDT
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfCurrencyTobeReturned == 0){ 
            dContract.transferFromTokens(XIVTokenContractAddress,msg.sender,databaseContractAddress,amountOfTokensToBeSold);
            dContract.transferETH(payable(msg.sender),calculateETHUSDTTobeGiven(amountOfTokensToBeSold,0));
        }else{
            dContract.transferFromTokens(XIVTokenContractAddress,msg.sender,databaseContractAddress,amountOfTokensToBeSold);
            dContract.transferTokens(USDTContractAddress,msg.sender,calculateETHUSDTTobeGiven(amountOfTokensToBeSold,1));
        }
        
    }
    function stakeTokens(uint256 amount) public{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        dContract.transferFromTokens(XIVTokenContractAddress,msg.sender,databaseContractAddress,amount);
        dContract.updateTokensStaked(msg.sender,dContract.getTokensStaked(msg.sender).add(amount));
        dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().add(amount));
        dContract.saveStakedAddress(true);
    }
     function unStakeTokens(uint256 amount) public{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        require(dContract.getTokensStaked(msg.sender)>=amount, "You don't have enough staking balance");
        dContract.transferTokens(XIVTokenContractAddress,msg.sender,amount);
        dContract.updateTokensStaked(msg.sender,dContract.getTokensStaked(msg.sender).sub(amount));
        dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(amount));
        dContract.saveStakedAddress(false);
    }
    
    
    function betFixed(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress) public{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        dContract.transferFromTokens(XIVTokenContractAddress,msg.sender,databaseContractAddress,amountOfXIV);
        
        if(typeOfBet==0){
            // defi fixed
            OracleWrapper oWObject=OracleWrapper(oracleWrapperContractAddress);
            XIVDatabaseLib.BetInfo memory binfo=XIVDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                amount:amountOfXIV,
                contractAddress:_betContractAddress,
                betType:typeOfBet,
                currentPrice:uint256(oWObject.getPrice(dContract.getDefiCoinsForFixedMapping(_betContractAddress).currencySymbol, dContract.getDefiCoinsForFixedMapping(_betContractAddress).oracleType)),
                checkpointPercent:dContract.getDefiCoinBetPercentage(),
                rewardFactor:0,
                riskFactor:0,
                timestamp:block.timestamp,
                status:0
            });
            dContract.updateBetArray(binfo);
            dContract.updateFindBetInArrayUsingBetIdMapping(dContract.getBetId(),dContract.getBetArray().length.sub(1));
            dContract.updateBetId(dContract.getBetId().add(1));
            
        }else if(typeOfBet==2){
            //index Fixed 
           
        }
    }
    
    function betFlexible(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress, uint256 betSlabeIndex) public{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        dContract.transferFromTokens(XIVTokenContractAddress,msg.sender,databaseContractAddress,amountOfXIV);
        if(typeOfBet==1){
            //defi flexible
            OracleWrapper oWObject=OracleWrapper(oracleWrapperContractAddress);
            XIVDatabaseLib.BetInfo memory binfo=XIVDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                amount:amountOfXIV,
                contractAddress:_betContractAddress,
                betType:typeOfBet,
                currentPrice:uint256(oWObject.getPrice(dContract.getDefiCoinsForFlexibleMapping(_betContractAddress).currencySymbol, dContract.getDefiCoinsForFlexibleMapping(_betContractAddress).oracleType)),
                checkpointPercent:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].upDownPercentage,
                rewardFactor:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].rewardFactor,
                riskFactor:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].riskFactor,
                timestamp:block.timestamp,
                status:0
            });
            dContract.updateBetArray(binfo);
            dContract.updateFindBetInArrayUsingBetIdMapping(dContract.getBetId(),dContract.getBetArray().length.sub(1));
            dContract.updateBetId(dContract.getBetId().add(1));
        }else if(typeOfBet==3){
            //index flexible
            
        }
    }
    
    function claimBet(uint256 userBetId) public{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 index=dContract.getFindBetInArrayUsingBetIdMapping(userBetId);
        require((dContract.getBetArray()[index].status==1) || (dContract.getBetArray()[index].status==2),"bet is closed.");
        if(dContract.getBetArray()[index].betType==0){
            // defi fixed
            if(dContract.getBetArray()[index].status==1){
                claimBetFixedFinal(index,true);
            }else{
                claimBetFixedFinal(index,false);
            }
        }else if(dContract.getBetArray()[index].betType==1){
            //defi flexible
            if(dContract.getBetArray()[index].status==1){
                claimBetFlexibleFinal(index,true);
            }else{
                claimBetFlexibleFinal(index,false);
            }
        }else if(dContract.getBetArray()[index].betType==2){
            //index Fixed 
            
        }else if(dContract.getBetArray()[index].betType==3){
            //index flexible
            
        }
    }
    
    function claimBetFixedFinal(uint256 index, bool isWon) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(isWon){
            uint256 amount=dContract.getBetArray()[index].amount.mul(3);
            dContract.transferTokens(XIVTokenContractAddress,msg.sender,amount);// return 3 times
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                uint256 updatedAmount=dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).sub((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(dContract.getBetArray()[index].amount.mul(2))).div(10**2)));
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],updatedAmount);
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(dContract.getBetArray()[index].amount.mul(2)));
        }else{
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).add((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(dContract.getBetArray()[index].amount.mul(2))).div(10**2))));
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().add(dContract.getBetArray()[index].amount.mul(2)));
        }
    }
    
    function claimBetFlexibleFinal(uint256 index, bool isWon) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(isWon){
            uint256 rewardAmount=(uint256(dContract.getBetArray()[index].rewardFactor).mul(dContract.getBetArray()[index].amount)).div(10**4);
            dContract.transferTokens(XIVTokenContractAddress,msg.sender,(dContract.getBetArray()[index].amount.add(rewardAmount)));
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                uint256 updatedAmount=dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).sub((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(rewardAmount)).div(10**2)));
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],updatedAmount);
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(rewardAmount));
        }else{
            uint256 riskAmount=(uint256(dContract.getBetArray()[index].riskFactor).mul(dContract.getBetArray()[index].amount)).div(10**4);
            dContract.transferTokens(XIVTokenContractAddress,msg.sender,(dContract.getBetArray()[index].amount.add(riskAmount)));// 
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                uint256 updatedAmount=dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).add((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(riskAmount)).div(10**2)));
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],updatedAmount);
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(riskAmount));
        }
    }
    
    function updateStatus() public{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(oracleWrapperContractAddress);
        for(uint256 i=0;i<dContract.getBetArray().length;i++){
            if(dContract.getBetArray()[i].status==0){
                uint256 sevenDaysTime=((((dContract.getBetArray()[i].timestamp).div(secondsInADay)).mul(secondsInADay)).add(sevenDays).sub(1));
                if(block.timestamp>=sevenDaysTime){
                     if(dContract.getBetArray()[i].betType==0){
                        // defi fixed
                        uint256 currentprice=uint256(oWObject.getPrice(dContract.getDefiCoinsForFixedMapping(dContract.getBetArray()[i].contractAddress).currencySymbol, dContract.getDefiCoinsForFixedMapping(dContract.getBetArray()[i].contractAddress).oracleType));
                        if(currentprice<dContract.getBetArray()[i].currentPrice){
                            uint16 percentageValue=uint16(((dContract.getBetArray()[i].currentPrice.sub(currentprice)).mul(10**4))
                                                    .div(dContract.getBetArray()[i].currentPrice));
                            if(percentageValue>=dContract.getBetArray()[i].checkpointPercent){
                                dContract.getBetArray()[i].status=1;
                            }else{
                                dContract.getBetArray()[i].status=2;
                            }
                        }else{
                            dContract.getBetArray()[i].status=2;
                        }
                    }else if(dContract.getBetArray()[i].betType==1){
                        //defi flexible
                         uint256 currentprice=uint256(oWObject.getPrice(dContract.getDefiCoinsForFlexibleMapping(dContract.getBetArray()[i].contractAddress).currencySymbol, dContract.getDefiCoinsForFlexibleMapping(dContract.getBetArray()[i].contractAddress).oracleType));
                        if(currentprice<dContract.getBetArray()[i].currentPrice){
                            uint16 percentageValue=uint16(((dContract.getBetArray()[i].currentPrice.sub(currentprice)).mul(10**4))
                                                    .div(dContract.getBetArray()[i].currentPrice));
                            if(percentageValue>=dContract.getBetArray()[i].checkpointPercent){
                                dContract.getBetArray()[i].status=1;
                            }else{
                                dContract.getBetArray()[i].status=2;
                            }
                        }else{
                            dContract.getBetArray()[i].status=2;
                        }
                    }else if(dContract.getBetArray()[i].betType==2){
                        //index Fixed 
                        
                    }else if(dContract.getBetArray()[i].betType==3){
                        //index flexible
                        
                    }
                }
            }
        }
    }
    
    function updateDatabaseAddress(address _databaseContractAddress) public onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
    
    function updateOrcaleAddress(address oracleAddress) public onlyOwner{
        oracleWrapperContractAddress=oracleAddress;
    }
}
