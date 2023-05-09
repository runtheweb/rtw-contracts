// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./IRunnerSoul.sol";

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

    function missionList(uint256 ind) external returns (address);
    function missionIds(address contr) external returns (uint256); // return id by address
    function totalMissions() external returns (uint256);
    function soulContract() external returns (IRunnerSoul);
    function rtw() external returns (IERC20);
    function vrfCoordinator() external returns (VRFCoordinatorV2Interface);
    function treasury() external returns (address);
    function subscriptionId() external returns (uint64);
    function treasuryFee() external returns (uint256);
    function extraReputation() external returns (uint256);
    function mintRtw(address to, uint256 amount) external;
    function burnRtw(address from, uint256 amount) external;
}
