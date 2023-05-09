// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMissionFactory.sol";

/// @title Mock RTX token with public mint

contract RtwToken is ERC20("RTW Token", "RTW"), Ownable {
    IMissionFactory public factory;

    // ================= ONWER FUNCTIONS =================

    /**
     * @notice Initialize contract dependencies
     * @dev Reinitialization available only for test purposes
     */
    function initialize(IMissionFactory _factory) external onlyOwner {
        factory = _factory;
    }

    // ================= USER FUNCTIONS =================

    /**
     * @notice Mint RTW to test MVP
     * @dev Will be deleted in production
     */
    function mintTest(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    // ================= MISSION FUNCTIONS =================

    function mint(address to, uint256 amount) external {
        require(factory.missionIds(msg.sender) > 0, "Can be called only by a mission");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(factory.missionIds(msg.sender) > 0, "Can be called only by a mission");
        _burn(from, amount);
    }
}
