// SPDX-License-Identifier: TGDK-BFE-ST-144
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TGDKUS_Oracle is Ownable {
    uint256 public constant PHI = 1618033988; // 1.618... scaled 1e9
    uint256 public constant PI  = 3141592653; // 3.1415... scaled 1e9
    uint256 public constant PMZ = 10200;      // 0.0102 scaled 1e6
    uint256 public rate;                      // scaled 1e9

    constructor() Ownable(msg.sender) {
        updateRate();
    }

    function updateRate() public onlyOwner {
        // K = (F/p)*(1+PMZ)
        rate = (PHI * (1e6 + PMZ)) / PI;
    }

    function convertToUSD(uint256 tgdkAmount) external view returns (uint256) {
        return (tgdkAmount * rate) / 1e9;
    }
}
