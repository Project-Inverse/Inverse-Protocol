// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./XIVInterface.sol";

contract XIVDatabase is Ownable{
    
    mapping (address=>uint256) public tokensStaked; //amount of XIV staked by user
    address[] public userStakedAddress;
    address[] tempArray;
    uint256 public tokenStakedAmount;
    address XIVMainContractAddress;
    
    mapping(address=>XIVDatabaseLib.DefiCoin) public defiCoinsForFixedMapping;
    address[] public allFixedContractAddressArray; 
    uint16 public defiCoinBetPercentage; //10**2
    
    mapping(address=>XIVDatabaseLib.DefiCoin) public defiCoinsForFlexibleMapping;
    address[] public allFlexibleContractAddressArray;
    
   
    XIVDatabaseLib.FlexibleInfo[] public flexibleDefiCoinArray;
    XIVDatabaseLib.FlexibleInfo[] public flexibleIndexArray;
    
    
    mapping(address=>XIVDatabaseLib.IndexCoin) public defiCoinsForFlexibleIndexMapping;
    address[] public allIndexFlexibleContractAddressArray;
    
    mapping(address=>XIVDatabaseLib.IndexCoin) public defiCoinsForFixedIndexMapping;
    address[] public allIndexFixedContractAddressArray;
    
    
    uint256 betid;
    
    XIVDatabaseLib.BetInfo[] public betArray;
    mapping(uint256=>uint256) public findBetInArrayUsingBetIdMapping; // getting the bet index using betid... Key is betId and value will be index in the betArray...
    
    constructor(){
        addUpdateForDefiCoinFixed(0xC4b3bB3a5e75958F5b7B0C518093F84B878C17e3,"TRB",2,true);
        addUpdateForDefiCoinFixed(0x3A435D2aeF6b369762A64C42f8fbD65d5F5e61fa,"LINK",1,true);
        addUpdateForDefiCoinFixed(0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF,"USDC",1,true);
        addUpdateForDefiCoinFlexible(0xC4b3bB3a5e75958F5b7B0C518093F84B878C17e3,"TRB",2,true);
        addUpdateForDefiCoinFlexible(0x3A435D2aeF6b369762A64C42f8fbD65d5F5e61fa,"LINK",1,true);
        addUpdateForDefiCoinFlexible(0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF,"USDC",1,true);
        addflexibleDefiCoinArray(300,3000,3000);
        addflexibleDefiCoinArray(400,4000,4000);
        addflexibleDefiCoinArray(500,5000,5000);
        addflexibleDefiCoinArray(600,6000,6000);
        addflexibleDefiCoinArray(700,7000,7000);
        
    }
    
    function addUpdateForDefiCoinFixed(address _ContractAddress, string memory _currencySymbol, 
                                        uint16 _OracleType,bool _Status) public onlyOwner{
        // add update defi fixed coin
        XIVDatabaseLib.DefiCoin memory dCoin=XIVDatabaseLib.DefiCoin({
            oracleType:_OracleType,
            currencySymbol:_currencySymbol,
            status:_Status
        });
        defiCoinsForFixedMapping[_ContractAddress]=dCoin;
        // check wheather contract exists in allFixedContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,allFixedContractAddressArray)){
            allFixedContractAddressArray.push(_ContractAddress);
        }
    }
    
    function addUpdateForDefiCoinFlexible(address _ContractAddress,  string memory _currencySymbol,
                                            uint16 _OracleType, bool _Status) public onlyOwner{
        // add update defi felxible coin
        XIVDatabaseLib.DefiCoin memory dCoin=XIVDatabaseLib.DefiCoin({
            oracleType:_OracleType,
            currencySymbol:_currencySymbol,
            status:_Status
        });
        defiCoinsForFlexibleMapping[_ContractAddress]=dCoin;
        // check wheather contract exists in allFlexibleContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,allFlexibleContractAddressArray)){
            allFlexibleContractAddressArray.push(_ContractAddress);
        }
    }
    
    function addflexibleDefiCoinArray(uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
        XIVDatabaseLib.FlexibleInfo memory fobject=XIVDatabaseLib.FlexibleInfo({
            id:flexibleDefiCoinArray.length,
            upDownPercentage:_upDownPercentage,
            riskFactor:_riskFactor,
            rewardFactor:_rewardFactor
        });
        flexibleDefiCoinArray.push(fobject);
    }
    function updateflexibleDefiCoinArray(uint256 index,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
        flexibleDefiCoinArray[index].upDownPercentage=_upDownPercentage;
        flexibleDefiCoinArray[index].riskFactor=_riskFactor;
        flexibleDefiCoinArray[index].rewardFactor=_rewardFactor;
    }
    
     function addUpdateForIndexCoinFlexible(address _ContractAddress, uint16 _OracleType, bool _Status, 
                                            uint256 _contributionPercentage) public onlyOwner{
        // add update index fixed coin
       XIVDatabaseLib.IndexCoin memory iCoin=XIVDatabaseLib.IndexCoin({
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
    function addflexibleIndexCoinArray(uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
        XIVDatabaseLib.FlexibleInfo memory fobject=XIVDatabaseLib.FlexibleInfo({
            id:flexibleDefiCoinArray.length,
            upDownPercentage:_upDownPercentage,
            riskFactor:_riskFactor,
            rewardFactor:_rewardFactor
        });
        flexibleIndexArray.push(fobject);
    }
    function updateflexibleIndexCoinArray(uint256 index,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
        flexibleIndexArray[index].upDownPercentage=_upDownPercentage;
        flexibleIndexArray[index].riskFactor=_riskFactor;
        flexibleIndexArray[index].rewardFactor=_rewardFactor;
    }
    
    function addUpdateForIndexCoinFixed(address _ContractAddress, uint16 _OracleType, bool _Status,
                                            uint256 _contributionPercentage) public onlyOwner{
        // add update index fixed coin
        XIVDatabaseLib.IndexCoin memory iCoin=XIVDatabaseLib.IndexCoin({
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
    function saveStakedAddress(bool fromStake) external onlyMyContracts{
        bool isAvailable=false;
        uint256 index;
        for(uint256 i=0;i<userStakedAddress.length;i++){
            if(userStakedAddress[i]==msg.sender){
                isAvailable=true;
                index=i;
                break;
            }
        }
        if(fromStake){
            if(!isAvailable){
                userStakedAddress.push(msg.sender);
            }  
        }else{
             if(isAvailable){
               userStakedAddress=removeIndex(index,userStakedAddress);
            } 
        }
    }
    function removeIndex(uint256 index, address[] memory addressArray) internal returns(address[] memory){
        tempArray=new address[](0);
        for(uint256 i=0;i<addressArray.length;i++){
            if(i!=index){
                tempArray.push(addressArray[i]);
            }
        }
        return tempArray;
    }
    function updateXIVMainContractAddress(address _XIVMainContractAddress) external onlyOwner{
        XIVMainContractAddress=_XIVMainContractAddress;
    }
    function updateDefiBetPercentage(uint16 _defiCoinBetPercentage) external onlyOwner{
        defiCoinBetPercentage=_defiCoinBetPercentage;
    }
    function transferETH(address payable userAddress,uint256 amount) external onlyMyContracts {
        require(address(this).balance >= amount,"The Contract does not have enough ethers.");
        userAddress.transfer(amount);
    }
    function transferTokens(address contractAddress,address userAddress,uint256 amount) external onlyMyContracts {
        Token tokenObj=Token(contractAddress);
        require(tokenObj.balanceOf(address(this))> amount, "Tokens not available");
        tokenObj.transfer(userAddress, amount);
    }
    function transferFromTokens(address contractAddress,address fromAddress, address toAddress,uint256 amount) external onlyMyContracts {
        require(checkTokens(contractAddress,amount,fromAddress));
        Token(contractAddress).transferFrom(fromAddress, toAddress, amount);
    }
    function checkTokens(address contractAddress,uint256 amount, address fromAddress) internal view returns(bool){
         Token tokenObj = Token(contractAddress);
        //check if user has balance
        require(tokenObj.balanceOf(fromAddress) >= amount, "You don't have enough XIV balance");
        //check if user has provided allowance
        require(tokenObj.allowance(fromAddress,address(this)) >= amount, 
        "Please allow smart contract to spend on your behalf");
        return true;
    }
    function getTokensStaked(address userAddress) external view returns(uint256){
        return (tokensStaked[userAddress]);
    }
    function updateTokensStaked(address userAddress, uint256 amount) external onlyMyContracts{
        tokensStaked[userAddress]=amount;
    }
    function getTokenStakedAmount() external view returns(uint256){
        return (tokenStakedAmount);
    }
    function updateTokenStakedAmount(uint256 _tokenStakedAmount) external onlyMyContracts{
        tokenStakedAmount=_tokenStakedAmount;
    }
    function getBetId() external view returns(uint256){
        return betid;
    }
    function updateBetId(uint256 _userBetId) external onlyMyContracts{
        betid=_userBetId;
    }
    function getDefiCoinsForFlexibleMapping(address _betContractAddress) external view returns(XIVDatabaseLib.DefiCoin memory){
        return (defiCoinsForFlexibleMapping[_betContractAddress]);
    }
    function updateDefiCoinsForFlexibleMapping(address _betContractAddress,XIVDatabaseLib.DefiCoin memory _defiCoinObj) external onlyMyContracts{
        defiCoinsForFlexibleMapping[_betContractAddress]=_defiCoinObj;
    }
    
    function getDefiCoinsForFixedMapping(address _betContractAddress) external view returns(XIVDatabaseLib.DefiCoin memory){
        return (defiCoinsForFixedMapping[_betContractAddress]);
    }
    function updateDefiCoinsForFixedMapping(address _betContractAddress,XIVDatabaseLib.DefiCoin memory _defiCoinObj) external onlyMyContracts{
        defiCoinsForFixedMapping[_betContractAddress]=_defiCoinObj;
    }
    
    function getDefiCoinBetPercentage() external view returns(uint16){
        return defiCoinBetPercentage;
    }
    function updateBetArray(XIVDatabaseLib.BetInfo memory bObject) external onlyMyContracts{
        betArray.push(bObject);
    }
    function getBetArray() external view returns(XIVDatabaseLib.BetInfo[] memory){
        return betArray;
    }
    function getFindBetInArrayUsingBetIdMapping(uint256 _betid) external view returns(uint256){
        return findBetInArrayUsingBetIdMapping[_betid];
    }
    function updateFindBetInArrayUsingBetIdMapping(uint256 _betid, uint256 value) external onlyMyContracts{
        findBetInArrayUsingBetIdMapping[_betid]=value;
    }
    function updateUserStakedAddress(address _address) external onlyMyContracts{
        userStakedAddress.push(_address);
    }
    function getUserStakedAddress() external view returns(address[] memory){
        return userStakedAddress;
    }
    function getFlexibleDefiCoinArray() external view returns(XIVDatabaseLib.FlexibleInfo[] memory){
        return flexibleDefiCoinArray;
    }
    modifier onlyMyContracts() {
        require(msg.sender == XIVMainContractAddress);
        _;
    }
}
