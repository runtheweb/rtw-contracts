// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Soul {
    uint256 reputation;
    uint256 soulPrice;
}

interface IRunnerSoul {
    function mintSoul() external; // pledge RTW and mint sould bound soul
    function setSoulPrice(uint256 price) external; // soul price in RTW
    function burnSoul() external; // burn soul and return collateral in RTW if reputation >= starting reputation
    function getReputation(address runner) external returns (uint256);
    function liquidateSoul(address runner) external; // if reputation = 0
}
