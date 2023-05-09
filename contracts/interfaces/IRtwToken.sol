// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMissionFactory.sol";

/// @title Mock RTX token with public mint

interface IRtwToken is IERC20 {
    function factory() external returns (IMissionFactory);

    function initialize(IMissionFactory _factory) external;
    function mintTest(uint256 amount) external;

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}
