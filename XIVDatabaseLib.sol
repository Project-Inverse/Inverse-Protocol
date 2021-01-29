// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

library XIVDatabaseLib{
    // deficoin struct for deficoinmappings..
    struct DefiCoin{
        uint16 oracleType;
        string currencySymbol;
        bool status;
    }
     struct FlexibleInfo{
        uint256 id;
        uint16 upDownPercentage; //10**2
        uint16 riskFactor;       //10**2
        uint16 rewardFactor;     //10**2
    }
    struct IndexCoin{
        uint16 oracleType;
        bool status;
        uint256 contributionPercentage; //10**2
    }
    struct BetInfo{
        uint256 id;
        uint256 amount;
        address contractAddress;
        uint256 betType;
        uint256 currentPrice;
        uint256 timestamp;
        uint16 checkpointPercent;
        uint16 rewardFactor;
        uint16 riskFactor;
        uint16 status; // 0->bet active, 1->bet won, 2->bet lost
    }
}
