// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

contract OracleWrapperInverse{
    address owner;
    bool isExtraAdded=false;
    address public tellerContractAddress;
    struct TellorInfo{
        uint256 id;
        uint256 tellorPSR;
    }
    uint256 tellorId=1;
    mapping(string=>address) public typeOneMapping;  // chainlink
    mapping(string=> TellorInfo) public typeTwomapping; // tellor
    mapping(string=>uint256) public staticPricesMapping;
    
    constructor(){
        owner= msg.sender;
    }
    
    function updateIsExtraAdded(bool _isExtraAdded) public onlyOwner{
        isExtraAdded = _isExtraAdded;
    }
    function updateStaticPricesMapping(string memory currencySymbol, uint256 amount) public onlyOwner{
        staticPricesMapping[currencySymbol] = amount;
    }
    
    function updateTellerContractAddress(address newAddress) public onlyOwner{
        tellerContractAddress = newAddress;
    }
    
    function addTypeOneMapping(string memory currencySymbol, address chainlinkAddress) public onlyOwner{
        typeOneMapping[currencySymbol]=chainlinkAddress;
    }
    
    function addTypeTwoMapping(string memory currencySymbol, uint256 tellorPSR) public onlyOwner{
        TellorInfo memory tInfo= TellorInfo({
            id:tellorId,
            tellorPSR:tellorPSR
        });
        typeTwomapping[currencySymbol]=tInfo;
        tellorId++;
    }
    
    function getPrice(string memory currencySymbol,
        uint256 oracleType) public view returns (uint256){
        //oracletype 1 - chainlink and  for teller
        if(oracleType == 1){
            require(typeOneMapping[currencySymbol]!=address(0), "please enter valid currency");
            OracleInterface oObj = OracleInterface(typeOneMapping[currencySymbol]);
            if(isExtraAdded){
                return(staticPricesMapping[currencySymbol]);
            }else{
                return uint256(oObj.latestAnswer());
            }
        }
        else{
            require(typeTwomapping[currencySymbol].id!=0, "please enter valid currency");
            tellorInterface tObj = tellorInterface(tellerContractAddress);
            uint256 actualFiatPrice;
            bool statusTellor;
            (actualFiatPrice,statusTellor) = tObj.getLastNewValueById(typeTwomapping[currencySymbol].tellorPSR);
              if(isExtraAdded){
                return(staticPricesMapping[currencySymbol]);
            }else{
                return uint256(actualFiatPrice);
            }
        }
    }
    
    modifier onlyOwner{
        require(owner==msg.sender,"Invalid Access.");
        _;
    }
}

interface OracleInterface{
    function latestAnswer() external view returns (int256);
}

interface tellorInterface{
     function getLastNewValueById(uint _requestId) external view returns(uint,bool);
}

