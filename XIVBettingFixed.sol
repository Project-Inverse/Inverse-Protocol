// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";

contract XIVBettingFixed is Ownable{
    
    using SafeMath for uint256;
    uint256 secondsInADay=86400;
    // uint256 sevenDays= 7 days;
    uint256 sevenDays= 300;
    address public databaseContractAddress=0xC4794a0DaaC8F4d6646656C0Df170f8573Aadf55;
    
    XIVDatabaseLib.IndexCoin[] tempObjectArray;
    
     function betFixed(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress) public{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        require(typeOfBet==0 || typeOfBet==2,"Invalid bet Type");
        require(checkIfBetExists(typeOfBet,_betContractAddress),"you can't place bet using these values.");
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfBet==0){
            require(dContract.getDefiCoinsForFixedMapping(_betContractAddress).status,"The currency is currently disabled.");
            // defi fixed
            OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
            XIVDatabaseLib.BetInfo memory binfo=XIVDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
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
            dContract.updateBetAddressesArray(msg.sender,dContract.getBetId());
            dContract.updateBetId(dContract.getBetId().add(1));
        }else if(typeOfBet==2){
            //index Fixed 
             XIVDatabaseLib.BetInfo memory binfo=XIVDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
                contractAddress:address(0),
                betType:typeOfBet,
                currentPrice:uint256(calculateIndexValueForFixedInternal(dContract.getBetId())),
                checkpointPercent:dContract.getDefiCoinBetIndexPercentage(),
                rewardFactor:0,
                riskFactor:0,
                timestamp:block.timestamp,
                status:0
            });
            dContract.updateBetArray(binfo);
            dContract.updateFindBetInArrayUsingBetIdMapping(dContract.getBetId(),dContract.getBetArray().length.sub(1));
            dContract.updateBetAddressesArray(msg.sender,dContract.getBetId());
            dContract.updateBetId(dContract.getBetId().add(1));
           
        }
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amountOfXIV);
    }
    function checkIfBetExists(uint16 typeOfBet, address _betContractAddress) internal view returns(bool){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256[] memory betIdArray=dContract.getBetsAccordingToUserAddress(msg.sender);
        for(uint256 i=0;i<betIdArray.length;i++){
            XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[dContract.getFindBetInArrayUsingBetIdMapping(i)];
            if(typeOfBet==0){
                if(bObject.status==0 && bObject.contractAddress==_betContractAddress){
                    return false;
                }
            }else{
                if(bObject.status==0){
                    return false;
                }
            }
        }
        return true;
    }
    function calculateIndexValueForBetActualFixed() public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexFixedAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexFixedAddressArray()[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFixedIndexMapping(dContract.getAllIndexFixedAddressArray()[i]);
            if(iCObj.status){
               totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
            }
        }
        return totalMarketcap;
    }
    function calculateIndexValueForBetBaseFixed() public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexFixedAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexFixedAddressArray()[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFixedIndexMapping(dContract.getAllIndexFixedAddressArray()[i]);
            if(iCObj.status){
               totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
            }
        }
         if(dContract.getBetBaseIndexValueFixed()==0){
            return (10**11);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValueFixed()){
                return (dContract.getBetBaseIndexValueFixed().add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValueFixed()))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFixed())));
            }else if(totalMarketcap<dContract.getBetActualIndexValueFixed()){
                return (dContract.getBetBaseIndexValueFixed().sub((
                                                     (dContract.getBetActualIndexValueFixed().sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFixed())));
            }
        }
        return (10**11);
    }
    function calculateIndexValueForFixedInternal(uint256 _betId) internal returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexFixedAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexFixedAddressArray()[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFixedIndexMapping(dContract.getAllIndexFixedAddressArray()[i]);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
                dContract.updateBetIndexForFixedArray(_betId,iCObj);
            }
        }
        XIVDatabaseLib.BetPriceHistory memory bPHObj=XIVDatabaseLib.BetPriceHistory({
            baseIndexValue:dContract.getBetBaseIndexValueFixed()==0?10**11:dContract.getBetBaseIndexValueFixed(),
            actualIndexValue:totalMarketcap
        });
        dContract.updateBetPriceHistoryFixedMapping(_betId,bPHObj);
        if(dContract.getBetBaseIndexValueFixed()==0){
            dContract.updateBetBaseIndexValueFixed(10**11);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValueFixed()){
                dContract.updateBetBaseIndexValueFixed(dContract.getBetBaseIndexValueFixed().add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValueFixed()))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFixed())));
            }else if(totalMarketcap<dContract.getBetActualIndexValueFixed()){
                dContract.updateBetBaseIndexValueFixed(dContract.getBetBaseIndexValueFixed().sub((
                                                     (dContract.getBetActualIndexValueFixed().sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFixed())));
            }
        }
        dContract.updateBetActualIndexValueFixed(totalMarketcap);
        return totalMarketcap;
    }
    function updateStatus() public {
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        for(uint256 i=0;i<dContract.getBetArray().length;i++){
            XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[i];
            if(bObject.status==0){
                uint256 sevenDaysTime=((((bObject.timestamp).div(secondsInADay)).mul(secondsInADay)).add(sevenDays).sub(1));
                if(block.timestamp>=sevenDaysTime){
                     if(bObject.betType==0){
                        // defi fixed
                        uint256 currentprice=uint256(oWObject.getPrice(dContract.getDefiCoinsForFixedMapping(bObject.contractAddress).currencySymbol, dContract.getDefiCoinsForFixedMapping(bObject.contractAddress).oracleType));
                       
                        if(currentprice<bObject.currentPrice){
                            uint16 percentageValue=uint16(((bObject.currentPrice.sub(currentprice)).mul(10**4))
                                                    .div(bObject.currentPrice));
                            if(percentageValue>=bObject.checkpointPercent){
                                updateXIVForStakersFixed(i, true,3);
                            }else{
                                updateXIVForStakersFixed(i, false,3);
                            }
                        }else{
                            updateXIVForStakersFixed(i, false,3);
                        }
                    }else if(bObject.betType==1){
                        //defi flexible
                         uint256 currentprice=uint256(oWObject.getPrice(dContract.getDefiCoinsForFlexibleMapping(bObject.contractAddress).currencySymbol, dContract.getDefiCoinsForFlexibleMapping(bObject.contractAddress).oracleType));
                        if(currentprice<bObject.currentPrice){
                            uint16 percentageValue=uint16(((bObject.currentPrice.sub(currentprice)).mul(10**4))
                                                    .div(bObject.currentPrice));
                            if(percentageValue>=bObject.checkpointPercent){
                                updateXIVForStakersFlexible(i, true);
                            }else{
                                updateXIVForStakersFlexible(i, false);
                            }
                        }else{
                            updateXIVForStakersFlexible(i, false);
                        }
                    }else if(bObject.betType==2){
                        //index Fixed 
                       updateXIVForStakersIndexFixed(i);
                        
                    }else if(bObject.betType==3){
                        //index flexible
                       updateXIVForStakersIndexFlexible(i);
                    }
                }
            }
        }
    }
    function updateXIVForStakersFixed(uint256 index, bool isWon, uint256 rewardMultipler) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        if(isWon){
            bObject.status=1;
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                uint256 updatedAmount=dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).sub((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(dContract.getBetArray()[index].amount.mul(rewardMultipler.sub(1)))).div(10**4)));
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],updatedAmount);
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(dContract.getBetArray()[index].amount.mul(rewardMultipler.sub(1))));
            bObject.amount=bObject.amount.mul(rewardMultipler); // return 3 times
            dContract.updateBetArrayIndex(bObject,index);
        }else{
            bObject.status=2;
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                uint256 updateAmount=dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).add((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(dContract.getBetArray()[index].amount)).div(10**4)));
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],updateAmount);
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().add(dContract.getBetArray()[index].amount));
            bObject.amount=0;
            dContract.updateBetArrayIndex(bObject,index);
        }
    }
    function updateXIVForStakersFlexible(uint256 index, bool isWon) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        if(isWon){
            bObject.status=1;
            uint256 rewardAmount=(uint256(dContract.getBetArray()[index].rewardFactor).mul(dContract.getBetArray()[index].amount)).div(10**4);
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                uint256 updatedAmount=dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).sub((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(rewardAmount)).div(10**4)));
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],updatedAmount);
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(rewardAmount));
            bObject.amount=bObject.amount.add(rewardAmount);
            dContract.updateBetArrayIndex(bObject,index);
        }else{
            bObject.status=2;
            uint256 riskAmount=(uint256(dContract.getBetArray()[index].riskFactor).mul(dContract.getBetArray()[index].amount)).div(10**4);
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                uint256 updatedAmount=dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).add((((dContract.getTokensStaked(dContract.getUserStakedAddress()[i]).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(riskAmount)).div(10**4)));
                dContract.updateTokensStaked(dContract.getUserStakedAddress()[i],updatedAmount);
            }
            dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().sub(riskAmount));
            bObject.amount=bObject.amount.sub(riskAmount);
            dContract.updateBetArrayIndex(bObject,index);
        }
    }
    
    function updateXIVForStakersIndexFixed(uint256 index) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        for(uint256 i=0;i<dContract.getBetIndexForFixedArray(bObject.id).length;i++){
            Token tObj=Token(dContract.getBetIndexForFixedArray(bObject.id)[i].contractAddress);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFixedIndexMapping(dContract.getBetIndexForFixedArray(bObject.id)[i].contractAddress);
            if(iCObj.status){
               totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
            }
        }
        if(dContract.getBetPriceHistoryFixedMapping(bObject.id).actualIndexValue>totalMarketcap){
             uint16 percentageValue=uint16(((dContract.getBetPriceHistoryFixedMapping(bObject.id).actualIndexValue.sub(totalMarketcap)
                                                     .mul(10**4)).div(dContract.getBetPriceHistoryFixedMapping(bObject.id).actualIndexValue)));
            if(percentageValue>=bObject.checkpointPercent){
                updateXIVForStakersFixed(index, true,2);
            }else{
                updateXIVForStakersFixed(index, false,2);
            }
        }else{
            updateXIVForStakersFixed(index, false,2);
        }
    }
    
    function updateXIVForStakersIndexFlexible(uint256 index) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        for(uint256 i=0;i<dContract.getBetIndexForFlexibleArray(bObject.id).length;i++){
            Token tObj=Token(dContract.getBetIndexForFlexibleArray(bObject.id)[i].contractAddress);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFlexibleIndexMapping(dContract.getBetIndexForFlexibleArray(bObject.id)[i].contractAddress);
            if(iCObj.status){
               totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
            }
        }
        if(dContract.getBetPriceHistoryFlexibleMapping(bObject.id).actualIndexValue>totalMarketcap){
             uint16 percentageValue=uint16(((dContract.getBetPriceHistoryFlexibleMapping(bObject.id).actualIndexValue.sub(totalMarketcap)
                                                     .mul(10**4)).div(dContract.getBetPriceHistoryFlexibleMapping(bObject.id).actualIndexValue)));
            if(percentageValue>=bObject.checkpointPercent){
                updateXIVForStakersFlexible(index, true);
            }else{
                updateXIVForStakersFlexible(index, false);
            }
        }else{
            updateXIVForStakersFlexible(index, false);
        }
    }
    
    function updateDatabaseAddress(address _databaseContractAddress) public onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
}
