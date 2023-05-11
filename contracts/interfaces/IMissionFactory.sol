// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IRtwToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./IRunnerSoul.sol";
import "./IRewardToken.sol";

interface IMissionFactory {
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

    function createSubscription(uint256 amount) external returns (uint64);
    function missionList(uint256 ind) external view returns (address);
    function missionIds(address contr) external view returns (uint256); // return id by address
    function totalMissions() external view returns (uint256);
    function soulContract() external view returns (IRunnerSoul);
    function rtw() external view returns (IRtwToken);
    function rewardToken() external view returns (IRewardToken);
    function vrfCoordinator() external view returns (VRFCoordinatorV2Interface);
    function treasury() external view returns (address);
    function subscriptionId() external view returns (uint64);
    function treasuryFee() external view returns (uint256);
    function extraReputation() external view returns (uint256);
    function mintRtw(address to, uint256 amount) external;
    function burnRtw(address from, uint256 amount) external;
}
