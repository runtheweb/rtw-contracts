// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IRtwToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./IRunnerSoul.sol";
import "./IRewardToken.sol";

interface IMissionFactory {
    // -- state
    function rtw() external view returns (IRtwToken); // rtw token address
    function soulContract() external view returns (IRunnerSoul); // contract of couriers souls
    function linkToken() external view returns (address); // link token address
    function vrfCoordinator() external view returns (VRFCoordinatorV2Interface); // address of vrf coordinator
    function rewardToken() external view returns (IRewardToken); // reward token address (soul bound trophy)
    function treasury() external view returns (address); // treasury address
    function missionList(uint256 ind) external view returns (address); // list of all missions
    function missionIds(address contr) external view returns (uint64); // get mission id by mission contract address
    function totalMissions() external view returns (uint32); // total number of all missions
    function subscriptionId() external view returns (uint64); // id of vrf subscribtion
    function treasuryFee() external view returns (uint32); // share of rewards which goes to the treasury
    function extraReputation() external view returns (uint32); // reputation bonus for mission success
    // -- owner
    function createSubscription() external; // create vrf subscription
    function fundSubscription(uint256 _linkAmount) external; // add link to subscription
    function changeTreasuryFee(uint32 _treasuryFee) external; // change treasury fee
    function changeExtraReputation(uint32 _extraReputation) external; // change extra reputation
    // -- create
    function createMission(
        string memory codex,
        uint256 totalRewardAmount,
        address operationToken,
        uint256 totalOperationAmount,
        uint256 minTotalCollateralPledge,
        uint256 numberOfCouriers,
        uint256 numberOfArbiters,
        uint256 executionTime,
        uint256 ratingTime
    )
        external;
}
