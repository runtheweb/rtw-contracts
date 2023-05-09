// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IMission.sol";

interface IRewardToken {
    function mintRewardToken(IMission _mission) external;
    function uri(uint256 id) external view returns (string memory);
}
