// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Pixel {
    uint256 x;
    uint256 y;
}

interface IPixelWar {
    function colorPixel(uint256 x, uint256 y, bytes3 color) external;
    function clearPixel(uint256 x, uint256 y) external;
}
