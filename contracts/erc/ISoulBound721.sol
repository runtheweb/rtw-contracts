// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISoulBound721 {
    function ownerOf(uint256 id) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
