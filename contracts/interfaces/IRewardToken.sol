// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IMission.sol";
import "../erc/ISoulBound1155.sol";

interface IRewardToken is ISoulBound1155 {
    // -- public
    function uri(uint256 id) external pure returns (string memory); // returns ""
    function getIdByMissionAddress(address mission) external pure returns (uint256); // get token id by mission address (if exists)
    // -- user
    function mintRewardToken(address _runner, IMission _mission) external; // mint soulbound trophy
}
