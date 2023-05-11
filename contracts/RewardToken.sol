// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./erc/SoulBound1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMissionFactory.sol";
import "./interfaces/IMission.sol";

contract RewardToken is SoulBound1155("Reward Token", "RTOKEN"), Ownable {
    IMissionFactory public factory;

    // ================= OWNER FUNCTIONS =================

    /**
     * @notice Initialize contract dependencies
     * @dev Reinitialization available only for test purposes
     */
    function initialize(IMissionFactory _factory) external onlyOwner {
        factory = _factory;
    }

    // ================= PUBLIC FUNCTIONS =================

    function uri(uint256 id) public view override returns (string memory) {
        return "";
    }

    function getIdByMissionAddress(address mission) public pure returns (uint256) {
        return uint256(uint160(address(mission)));
    }

    // ================= USER FUNCTIONS =================

    function mintRewardToken(address _runner, IMission _mission) external {
        require(factory.missionIds(address(_mission)) > 0, "Address is not a mission");

        bool res_ = _mission.runnerResult(_runner);
        require(res_, "Cannot mint unsuccessfully passed mission reward");

        uint256 rewardId_ = getIdByMissionAddress(address(_mission));
        require(balanceOf[_runner][rewardId_] == 0, "Mission reward already minted");

        _mint(_runner, rewardId_, 1, "");
    }
}
