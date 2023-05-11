// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Pixel {
    int256 x;
    int256 y;
}

interface IPixelWar {
    function colorPixel(int16 x, int16 y, bytes3 color) external;
    function clearPixel(int16 x, int16 y) external;

    function totalPixels() external view returns (uint256);
    function userReputation(address user) external view returns (uint256);
    function isColorable(int16 x, int16 y) external view returns (bool);
    function isClearable(int16 x, int16 y) external view returns (bool);
    function availablePixels(address user) external view returns (uint256);
}
