// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";

contract XIVDatabase is Ownable{
    
    using SafeMath for uint256;
    mapping (address=>uint256) public tokensStaked; //amount of XIV staked by user
    address[] public userStakedAddress;
    address[] tempArray;
    // XIVDatabaseLib.BetInfo[] tempBetArray;
    uint256 public tokenStakedAmount;
    
    uint256 public adminStakingFee;// 10**2
    address public adminAddress;
    
    address XIVMainContractAddress;
    address XIVBettingFixedContractAddress;
    address XIVBettingFlexibleContractAddress;
    
    address oracleWrapperContractAddress = 0x727D4c4401aC0a4F430cc7e9B743B7970e1929b9; //address of oracle wrapper from where the prices would be fetched
    address XIVTokenContractAddress = 0x7a8D6925cb8faB279883ac3DBccf6f2029eB1315; //XIV contract address
    address USDTContractAddress = 0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF; //USDT contract address
    
    mapping(address=>XIVDatabaseLib.DefiCoin) public defiCoinsForFixedMapping;
    address[] public allFixedContractAddressArray; 
    uint16 public defiCoinBetPercentage; //10**2
    
    mapping(address=>XIVDatabaseLib.DefiCoin) public defiCoinsForFlexibleMapping;
    address[] public allFlexibleContractAddressArray;
    
    XIVDatabaseLib.FlexibleInfo[] public flexibleDefiCoinArray;
    
    mapping(address=>XIVDatabaseLib.IndexCoin) public defiCoinsForFlexibleIndexMapping;
    address[] public allIndexFlexibleContractAddressArray;
    XIVDatabaseLib.FlexibleInfo[] public flexibleIndexArray;
    uint256 public betBaseIndexValueFlexible; //10**8
    uint256 public betActualIndexValueFlexible;
    mapping(uint256=>XIVDatabaseLib.IndexCoin[]) betIndexForFlexibleArray; // this include array of imdex on which bet is placed. key will be betId and value will be array of all index... 
    mapping(uint256=>XIVDatabaseLib.BetPriceHistory) betPriceHistoryFlexibleMapping;
    
    mapping(address=>XIVDatabaseLib.IndexCoin) public defiCoinsForFixedIndexMapping;
    address[] public allIndexFixedContractAddressArray;
    uint16 public defiCoinBetIndexPercentage; //10**2
    uint256 public betBaseIndexValueFixed; //10**8
    uint256 public betActualIndexValueFixed;
    mapping(uint256=>XIVDatabaseLib.IndexCoin[]) betIndexForFixedArray; // this include array of imdex on which bet is placed. key will be betId and value will be array of all index... 
    mapping(uint256=>XIVDatabaseLib.BetPriceHistory) betPriceHistoryFixedMapping;
    
    uint256 betid;
    
    XIVDatabaseLib.BetInfo[] public betArray;
    mapping(uint256=>uint256) public findBetInArrayUsingBetIdMapping; // getting the bet index using betid... Key is betId and value will be index in the betArray...
    mapping(address=> uint256[]) public betAddressesArray;
    
    mapping(uint256=>uint256) public plentyPercentage; // key is day and value is percentage in 10**2
    
    uint256 rewardGeneratedAmount;
    address[] userAddressUsedForBetting;
    
    constructor(){
        addUpdateForDefiCoinFixed(0xC4b3bB3a5e75958F5b7B0C518093F84B878C17e3,"TRB",2,true);
        addUpdateForDefiCoinFixed(0x3A435D2aeF6b369762A64C42f8fbD65d5F5e61fa,"LINK",1,true);
        addUpdateForDefiCoinFixed(0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF,"USDC",1,true);
        addUpdateForDefiCoinFlexible(0xC4b3bB3a5e75958F5b7B0C518093F84B878C17e3,"TRB",2,true);
        addUpdateForDefiCoinFlexible(0x3A435D2aeF6b369762A64C42f8fbD65d5F5e61fa,"LINK",1,true);
        addUpdateForDefiCoinFlexible(0xBbf126a88DE8c993BFe67c46Bb333a2eC71bC3fF,"USDC",1,true);
        addflexibleDefiCoinArray(900,1000,1000);
        addflexibleDefiCoinArray(1000,2000,2000);
        addflexibleDefiCoinArray(1200,4000,4000);
        addflexibleDefiCoinArray(1400,7000,7000);
        addflexibleDefiCoinArray(1500,10000,10000);
        
        addflexibleIndexCoinArray(900,1000,1000);
        addflexibleIndexCoinArray(1000,2000,2000);
        addflexibleIndexCoinArray(1200,4000,4000);
        addflexibleIndexCoinArray(1400,7000,7000);
        addflexibleIndexCoinArray(1500,10000,10000);
        addUpdatePlentyPercentage(0,10000);
        addUpdatePlentyPercentage(1,5000);
        addUpdatePlentyPercentage(2,5000);
        addUpdatePlentyPercentage(3,6000);
        addUpdatePlentyPercentage(4,7000);
        addUpdatePlentyPercentage(5,8000);
        addUpdatePlentyPercentage(6,9000);
        addUpdatePlentyPercentage(7,10000);
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
    
     function addUpdateForIndexCoinFlexible(XIVDatabaseLib.IndexCoin[] memory tupleCoinArray) public onlyOwner{
        // add update index fixed coin
        uint256 totalContribution;
        for(uint256 i=0;i<tupleCoinArray.length;i++){
            totalContribution=totalContribution.add(tupleCoinArray[i].contributionPercentage);
        }
        require(totalContribution==10000,"Total contribution Percentage should be 100");
        tempArray=new address[](0);
        allIndexFlexibleContractAddressArray=tempArray;
        
        for(uint256 i=0;i<tupleCoinArray.length;i++){
            defiCoinsForFlexibleIndexMapping[tupleCoinArray[i].contractAddress]=tupleCoinArray[i];
            // check wheather contract exists in allFixedContractAddressArray array
            if(!contractAvailableInArray(tupleCoinArray[i].contractAddress,allIndexFlexibleContractAddressArray)){
                allIndexFlexibleContractAddressArray.push(tupleCoinArray[i].contractAddress);
            }
        }
    }
    function addflexibleIndexCoinArray(uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
        XIVDatabaseLib.FlexibleInfo memory fobject=XIVDatabaseLib.FlexibleInfo({
            id:flexibleIndexArray.length,
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
    
    function addUpdateForIndexCoinFixed(XIVDatabaseLib.IndexCoin[] memory tupleCoinArray) public onlyOwner{
        // add update index fixed coin
        uint256 totalContribution;
        for(uint256 i=0;i<tupleCoinArray.length;i++){
            totalContribution=totalContribution.add(tupleCoinArray[i].contributionPercentage);
        }
        require(totalContribution==10000,"Total contribution Percentage should be 100");
        tempArray=new address[](0);
        allIndexFixedContractAddressArray=tempArray;
        for(uint256 i=0;i<tupleCoinArray.length;i++){
            defiCoinsForFixedIndexMapping[tupleCoinArray[i].contractAddress]=tupleCoinArray[i];
            // check wheather contract exists in allFixedContractAddressArray array
            if(!contractAvailableInArray(tupleCoinArray[i].contractAddress,allIndexFixedContractAddressArray)){
                allIndexFixedContractAddressArray.push(tupleCoinArray[i].contractAddress);
            }
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
    function saveStakedAddress(bool fromStake, address userAddress) external onlyMyContracts{
        bool isAvailable=false;
        uint256 index;
        for(uint256 i=0;i<userStakedAddress.length;i++){
            if(userStakedAddress[i]==userAddress){
                isAvailable=true;
                index=i;
                break;
            }
        }
        if(fromStake){
            if(!isAvailable){
                userStakedAddress.push(userAddress);
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
    function updateXIVBettingFixedContractAddress(address _XIVBettingFixedContractAddress) external onlyOwner{
        XIVBettingFixedContractAddress=_XIVBettingFixedContractAddress;
    }
    function updateXIVBettingFlexibleContractAddress(address _XIVBettingFlexibleContractAddress) external onlyOwner{
        XIVBettingFlexibleContractAddress=_XIVBettingFlexibleContractAddress;
    }
    function updateXIVTokenContractAddress(address _XIVTokenContractAddress) external onlyOwner{
        XIVTokenContractAddress=_XIVTokenContractAddress;
    }
    function getXIVTokenContractAddress() external view returns(address){
        return XIVTokenContractAddress;
    }
    function updateUSDTContractAddress(address _USDTContractAddress) external onlyOwner{
        USDTContractAddress=_USDTContractAddress;
    }
    function getUSDTContractAddress() external view returns(address){
        return USDTContractAddress;
    }
    function updateDefiBetPercentage(uint16 _defiCoinBetPercentage) external onlyOwner{
        defiCoinBetPercentage=_defiCoinBetPercentage;
    }
    function getDefiCoinBetPercentage() external view returns(uint16){
        return defiCoinBetPercentage;
    }
    function updateDefiBetIndexPercentage(uint16 _defiCoinBetIndexPercentage) external onlyOwner{
        defiCoinBetIndexPercentage=_defiCoinBetIndexPercentage;
    }
    function getDefiCoinBetIndexPercentage() external view returns(uint16){
        return defiCoinBetIndexPercentage;
    }
    function updateBetBaseIndexValueFixed(uint256 _betBaseIndexValueFixed) external onlyMyContracts{
        betBaseIndexValueFixed=_betBaseIndexValueFixed;
    }
    function getBetBaseIndexValueFixed() external view returns(uint256){
        return betBaseIndexValueFixed;
    }
    function updateBetBaseIndexValueFlexible(uint256 _betBaseIndexValueFlexible) external onlyMyContracts{
        betBaseIndexValueFlexible=_betBaseIndexValueFlexible;
    }
    function getBetBaseIndexValueFlexible() external view returns(uint256){
        return betBaseIndexValueFlexible;
    }
    function updateBetActualIndexValueFixed(uint256 _betActualIndexValueFixed) external onlyMyContracts{
        betActualIndexValueFixed=_betActualIndexValueFixed;
    }
    function getBetActualIndexValueFixed() external view returns(uint256){
        return betActualIndexValueFixed;
    }
    function updateBetActualIndexValueFlexible(uint256 _betActualIndexValueFlexible) external onlyMyContracts{
        betActualIndexValueFlexible=_betActualIndexValueFlexible;
    }
    function getBetActualIndexValueFlexible() external view returns(uint256){
        return betActualIndexValueFlexible;
    }
    
    function transferETH(address payable userAddress,uint256 amount) external onlyMyContracts {
        require(address(this).balance >= amount,"The Contract does not have enough ethers.");
        userAddress.transfer(amount);
    }
    function transferTokens(address contractAddress,address userAddress,uint256 amount) external onlyMyContracts {
        Token tokenObj=Token(contractAddress);
        require(tokenObj.balanceOf(address(this))>= amount, "Tokens not available");
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
    
    function updateBetArray(XIVDatabaseLib.BetInfo memory bObject) external onlyMyContracts{
        betArray.push(bObject);
    }
    function updateBetArrayIndex(XIVDatabaseLib.BetInfo memory bObject, uint256 index) external onlyMyContracts{
        betArray[index]=bObject;
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
    
    function getFlexibleIndexArray() external view returns(XIVDatabaseLib.FlexibleInfo[] memory){
        return flexibleIndexArray;
    }
    
    function getAllIndexFixedAddressArray() external view returns(address[] memory){
        return allIndexFixedContractAddressArray;
    }
    function getAllFixedContractAddressArray() external view returns(address[] memory){
        return allFixedContractAddressArray;
    }
    function getAllFlexibleContractAddressArray() external view returns(address[] memory){
        return allFlexibleContractAddressArray;
    }
    function getAllIndexFlexibleContractAddressArray() external view returns(address[] memory){
        return allIndexFlexibleContractAddressArray;
    }
    function getDefiCoinForFixedIndexMapping(address _ContractAddress) external view returns(XIVDatabaseLib.IndexCoin memory){
        return (defiCoinsForFixedIndexMapping[_ContractAddress]);
    }
    function getDefiCoinForFlexibleIndexMapping(address _ContractAddress) external view returns(XIVDatabaseLib.IndexCoin memory){
        return (defiCoinsForFlexibleIndexMapping[_ContractAddress]);
    }
    function updateBetIndexForFixedArray(uint256 _betId, XIVDatabaseLib.IndexCoin memory iCArray) external onlyMyContracts{
        betIndexForFixedArray[_betId].push(iCArray);
    }
    function getBetIndexForFixedArray(uint256 _betId) external view returns(XIVDatabaseLib.IndexCoin[] memory){
        return (betIndexForFixedArray[_betId]);
    }
    function updateBetIndexForFlexibleArray(uint256 _betId, XIVDatabaseLib.IndexCoin memory iCArray) external onlyMyContracts{
        betIndexForFlexibleArray[_betId].push(iCArray);
    }
    function getBetIndexForFlexibleArray(uint256 _betId) external view returns(XIVDatabaseLib.IndexCoin[] memory){
        return (betIndexForFlexibleArray[_betId]);
    }
    function updateBetPriceHistoryFixedMapping(uint256 _betId, XIVDatabaseLib.BetPriceHistory memory bPHObj) external onlyMyContracts{
        betPriceHistoryFixedMapping[_betId]=bPHObj;
    }
    function getBetPriceHistoryFixedMapping(uint256 _betId) external view returns(XIVDatabaseLib.BetPriceHistory memory){
        return (betPriceHistoryFixedMapping[_betId]);
    }
    function updateBetPriceHistoryFlexibleMapping(uint256 _betId, XIVDatabaseLib.BetPriceHistory memory bPHObj) external onlyMyContracts{
        betPriceHistoryFlexibleMapping[_betId]=bPHObj;
    }
    function getBetPriceHistoryFlexibleMapping(uint256 _betId) external view returns(XIVDatabaseLib.BetPriceHistory memory){
        return (betPriceHistoryFlexibleMapping[_betId]);
    }
    function addUpdatePlentyPercentage(uint256 _days, uint256 percentage) public onlyOwner{
        plentyPercentage[_days]=percentage;
    }
    function getPlentyPercentage(uint256 _days) external view returns(uint256){
        return (plentyPercentage[_days]);
    }
    function updateOrcaleAddress(address oracleAddress) external onlyOwner{
        oracleWrapperContractAddress=oracleAddress;
    }
    function getOracleWrapperContractAddress() external view returns(address){
        return oracleWrapperContractAddress;
    }
    function getAdminStakingFee() external view returns(uint256){
        return adminStakingFee;
    }
    function updateAdminStakingFee(uint256 _adminStakingFee) external onlyOwner{
        adminStakingFee=_adminStakingFee;
    }
    function getAdminAddress() external view returns(address){
        return adminAddress;
    }
    function updateAdminAddress(address _adminAddress) external onlyOwner{
        adminAddress=_adminAddress;
    }
    function getBetsAccordingToUserAddress(address userAddress) external view returns(uint256[] memory){
        return betAddressesArray[userAddress];
    }
    function updateBetAddressesArray(address userAddress, uint256 _betId) external onlyMyContracts{
        betAddressesArray[userAddress].push(_betId);
    }
    function getRewardGeneratedAmount() external view returns(uint256){
        return rewardGeneratedAmount;
    }
    function updateRewardGeneratedAmount(uint256 _rewardGeneratedAmount) external onlyMyContracts{
        rewardGeneratedAmount=_rewardGeneratedAmount;
    }
    
    function addUserAddressUsedForBetting(address userAddress) external onlyMyContracts{
        userAddressUsedForBetting.push(userAddress);
    }
    function getUserAddressUsedForBetting() external view returns(address[] memory){
        return userAddressUsedForBetting;
    }
    modifier onlyMyContracts() {
        require(msg.sender == XIVMainContractAddress || msg.sender==XIVBettingFixedContractAddress || msg.sender== XIVBettingFlexibleContractAddress);
        _;
    }
    fallback() external payable {
    }
}
