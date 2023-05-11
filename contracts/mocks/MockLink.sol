// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC677TransferReceiver {
    function tokenFallback(address from, uint256 amount, bytes calldata data) external returns (bool);
}

/// @title Mock LINK token with free mint
contract MockLink is ERC20("LINK", "LINK") {
    function transferAndCall(address to, uint256 value, bytes memory data) external returns (bool) {
        bool result = super.transfer(to, value);
        if (!result) {
            return false;
        }

        IERC677TransferReceiver receiver = IERC677TransferReceiver(to);
        receiver.tokenFallback(msg.sender, value, data);
        return true;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
