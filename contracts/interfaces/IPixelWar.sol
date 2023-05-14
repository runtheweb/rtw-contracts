// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IRunnerSoul.sol";

struct Pixel {
    int256 x;
    int256 y;
}

interface IPixelWar {
    // -- state
    function soulContract() external view returns (IRunnerSoul); // reputation provider contract
    function colors(int16 x, int16 y) external view returns (bytes3); // get owner of pixel
    function owners(int16 x, int16 y) external view returns (address); // get owner of pixel
    function totalUserPixels(address user) external view returns (uint256); // number of pixels by user
    function allPixels(uint256 ind) external view returns (Pixel memory); // list of pixels
    function pixelCost() external view returns (uint256); // reputation required for 1 pixel
    // -- owner
    function changePixelCost(uint256 _pixelCost) external; // change pixel cost
    // -- users
    function colorPixel(int16 x, int16 y, bytes3 color) external; // color pixel
    function clearPixel(int16 x, int16 y) external; // clear colored pixel
    // -- public
    function totalPixels() external view returns (uint256); // total number of touched pixels
    function userReputation(address user) external view returns (uint256); // get reputation of user
    function isColorable(int16 x, int16 y) external view returns (bool); // can a pixel be colored or not
    function isClearable(int16 x, int16 y) external view returns (bool); // can a pixel be cleared or not
    function availablePixels(address user) external view returns (uint256); // number of available pixels for user
}
