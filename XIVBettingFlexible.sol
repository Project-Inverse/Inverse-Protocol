// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";

contract XIVBettingFlexible is Ownable{
    
    using SafeMath for uint256;
    address public databaseContractAddress=0xA500f7620DE3Ab37699D119dB5DCB348B07deF7F;
    
    XIVDatabaseLib.IndexCoin[] tempObjectArray;
    
    function betFlexible(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress, uint256 betSlabeIndex) external{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        require(typeOfBet==1 || typeOfBet==3, "Invalid bet Type");
        require(checkIfBetExists(typeOfBet,_betContractAddress),"you can't place bet using these values.");
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(typeOfBet==1){
            //defi flexible
            require(dContract.getDefiCoinsForFlexibleMapping(_betContractAddress).status,"The currency is currently disabled.");
            OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
            XIVDatabaseLib.BetInfo memory binfo=XIVDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
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
            dContract.updateBetAddressesArray(msg.sender,dContract.getBetId());
            dContract.updateBetId(dContract.getBetId().add(1));
        }else if(typeOfBet==3){
            //index flexible
            XIVDatabaseLib.BetInfo memory binfo=XIVDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
                contractAddress:address(0),
                betType:typeOfBet,
                currentPrice:uint256(calculateIndexValueForFlexibleInternal(dContract.getBetId())),
                checkpointPercent:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].upDownPercentage,
                rewardFactor:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].rewardFactor,
                riskFactor:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].riskFactor,
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
            if(typeOfBet==1){
                if(bObject.status==0 && bObject.contractAddress==_betContractAddress && bObject.betType==1){
                    return false;
                }
            }else if(typeOfBet==3){
                if(bObject.status==0 && bObject.betType==3){
                    return false;
                }
            }
        }
        return true;
    }
    function calculateIndexValueForBetActualFlexible() external view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexFlexibleContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexFlexibleContractAddressArray()[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFlexibleIndexMapping(dContract.getAllIndexFlexibleContractAddressArray()[i]);
            if(iCObj.status){
               totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
            }
        }
        return totalMarketcap;
    }
    function calculateIndexValueForBetBaseFlexible() external view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexFlexibleContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexFlexibleContractAddressArray()[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFlexibleIndexMapping(dContract.getAllIndexFlexibleContractAddressArray()[i]);
            if(iCObj.status){
               totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
            }
        }
        if(dContract.getBetBaseIndexValueFlexible()==0){
            return (10**11);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValueFlexible()){
                return (dContract.getBetBaseIndexValueFlexible().add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValueFlexible()))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFlexible())));
            }else if(totalMarketcap<dContract.getBetActualIndexValueFlexible()){
                return (dContract.getBetBaseIndexValueFlexible().sub((
                                                     (dContract.getBetActualIndexValueFlexible().sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFlexible())));
            }
        }
        return (10**11);
    }
    function calculateIndexValueForFlexibleInternal(uint256 _betId) internal returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexFlexibleContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexFlexibleContractAddressArray()[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinForFlexibleIndexMapping(dContract.getAllIndexFlexibleContractAddressArray()[i]);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(((
                    tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    .mul(iCObj.contributionPercentage))
                                    .div((10**tObj.decimals()).mul(10**4))));
                dContract.updateBetIndexForFlexibleArray(_betId,iCObj);
            }
        }
        XIVDatabaseLib.BetPriceHistory memory bPHObj=XIVDatabaseLib.BetPriceHistory({
            baseIndexValue:dContract.getBetBaseIndexValueFlexible()==0?10**11:dContract.getBetBaseIndexValueFlexible(),
            actualIndexValue:totalMarketcap
        });
        dContract.updateBetPriceHistoryFlexibleMapping(_betId,bPHObj);
        if(dContract.getBetBaseIndexValueFlexible()==0){
            dContract.updateBetBaseIndexValueFlexible(10**11);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValueFlexible()){
                dContract.updateBetBaseIndexValueFlexible(dContract.getBetBaseIndexValueFlexible().add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValueFlexible()))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFlexible())));
            }else if(totalMarketcap<dContract.getBetActualIndexValueFlexible()){
                dContract.updateBetBaseIndexValueFlexible(dContract.getBetBaseIndexValueFlexible().sub((
                                                     (dContract.getBetActualIndexValueFlexible().sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValueFlexible())));
            }
        }
        dContract.updateBetActualIndexValueFlexible(totalMarketcap);
        return totalMarketcap;
    }
    
    function claimBet(uint256 userBetId) external{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 index=dContract.getFindBetInArrayUsingBetIdMapping(userBetId);
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        require((bObject.status==0) 
                || (bObject.status==1)
                || (bObject.status==2),"bet is closed.");
        if(bObject.status==0){
            if(block.timestamp.sub(bObject.timestamp) > 7 days){
                plentyFinal(index,7);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 6 days){
                plentyFinal(index,6);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 5 days){
                plentyFinal(index,5);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 4 days){
                plentyFinal(index,4);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 3 days){
                plentyFinal(index,3);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 2 days){
                plentyFinal(index,2);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 1 days){
                plentyFinal(index,1);
                return;
            }else{
                plentyFinal(index,0);
                return;
            }
        }else{
            if(bObject.betType==0){
            // defi fixed
            claimBetFinal(index);
            }else if(bObject.betType==1){
                //defi flexible
                claimBetFinal(index);
            }else if(bObject.betType==2){
                //index Fixed 
                claimBetFinal(index);
            }else if(bObject.betType==3){
                //index flexible
                claimBetFinal(index);
            }
        }
    }
    
    function claimBetFinal(uint256 index) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        require(bObject.userAddress==msg.sender,"Authentication failure");
        require(bObject.amount!=0,"Your bed amount is 0");
        dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,(bObject.amount)); 
        bObject.amount=0; // return 3 times
        dContract.updateBetArrayIndex(bObject,index);
    }
    function plentyFinal(uint256 index, uint256 _days) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        uint256 plentyAmount=((dContract.getPlentyPercentage(_days).mul(bObject.amount)).div(10**4));
        uint256 userAmount=(bObject.amount).sub(plentyAmount);
        if(userAmount!=0){
            dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,userAmount); 
        }
        bObject.status=3;
        bObject.amount=0;
            for(uint256 i=0;i<dContract.getUserStakedAddress().length;i++){
                address userAddress=dContract.getUserStakedAddress()[i];
                uint256 updatedAmount=dContract.getTokensStaked(userAddress).add((((dContract.getTokensStaked(userAddress).mul(10**4)).div(dContract.getTokenStakedAmount()).mul(plentyAmount)).div(10**4)));
                dContract.updateTokensStaked(userAddress,updatedAmount);
            }
        dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount().add(plentyAmount));
        dContract.updateBetArrayIndex(bObject,index);
    }
    function updateDatabaseAddress(address _databaseContractAddress) external onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
}
