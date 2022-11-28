// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMissionFactory {
    function createMission(
        string memory codex,
        uint256 rewardAmount,
        address operationToken,
        uint256 operationAmount,
        uint256 minCollateralPledge, // in usd
        uint256 numberOfCouriers,
        uint256 numberOfArbiters,
        uint256 executionTime, // time to couriers to run
        uint256 ratingTime // time for arbitres to vote
    )
        external;

    function missionList(uint256 ind) external returns (address);
    function missionIds(address contr) external returns (uint256); // return id by address
    function totalMissions() external returns (uint256);
}
