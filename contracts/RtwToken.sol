// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Mock RTX token with public mint

contract RtwToken is ERC20("RTW Token", "RTW") {
    function mintTest(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
