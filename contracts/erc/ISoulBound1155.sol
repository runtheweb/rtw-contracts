// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISoulBound1155 {
    function uri(uint256 id) external view returns (string memory);
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory balances);
    function balanceOf(address who, uint256 id) external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
