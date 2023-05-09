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

    // ================= USER FUNCTIONS =================

    function mintRewardToken(IMission _mission) external {
        require(factory.missionIds(address(_mission)) > 0, "Address is not a mission");

        bool res_ = _mission.runnerResult(msg.sender);
        require(res_, "Cannot mint unsuccessfully passed mission reward");

        uint256 rewardId_ = uint256(uint160(address(_mission)));
        require(balanceOf[msg.sender][rewardId_] == 0, "Mission reward already minted");

        _mint(msg.sender, rewardId_, 1, "");
    }
}
