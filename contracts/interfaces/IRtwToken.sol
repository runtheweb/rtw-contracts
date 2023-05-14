// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMissionFactory.sol";

/// @title Mock RTX token with public mint

interface IRtwToken is IERC20 {
    // -- state
    function factory() external returns (IMissionFactory); // mission factory address
    // -- user
    function mintTest(uint256 amount) external; // mint test rtw tokens
    // -- special
    function mint(address to, uint256 amount) external; // only for a mission contract
    function burn(address from, uint256 amount) external; // only for a mission contract
}
