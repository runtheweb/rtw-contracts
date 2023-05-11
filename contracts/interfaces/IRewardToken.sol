// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IMission.sol";
import "../erc/ISoulBound1155.sol";

interface IRewardToken is ISoulBound1155 {
    function mintRewardToken(address _runner, IMission _mission) external;
    function uri(uint256 id) external view returns (string memory);
    function getIdByMissionAddress(address mission) external pure returns (uint256);
}
