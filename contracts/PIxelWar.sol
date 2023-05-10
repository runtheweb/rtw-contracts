// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRunnerSoul.sol";
import "./interfaces/IPixelWar.sol";

contract PixelWar is Ownable {
    event PixelColored(address indexed user, Pixel indexed pixel, bytes3 color);
    event PixelCleared(address indexed user, Pixel indexed pixel);

    IRunnerSoul public soulContract;

    mapping(uint256 => mapping(uint256 => bytes3)) public colors;
    mapping(uint256 => mapping(uint256 => address)) public owners;
    mapping(address => uint256) public totalUserPixels;
    Pixel[] public allPixels;

    uint256 public pixelCost; // cost of 1 pixel in reputation (18 decimals)

    // ================= CONSTRUCTOR FUNCTIONS =================

    constructor(uint256 _pixelCost) {
        require(_pixelCost > 0, "Pixel cost cannot be zero");
        pixelCost = _pixelCost;
    }

    // ================= OWNER FUNCTIONS =================

    /**
     * @notice Initialize contract dependencies
     * @dev Reinitialization available only for test purposes
     */
    function initialize(IRunnerSoul _soulContract) external onlyOwner {
        soulContract = _soulContract;
    }

    function changePixelCost(uint256 _pixelCost) external onlyOwner {
        require(_pixelCost > 0, "Pixel cost cannot be zero");
        pixelCost = _pixelCost;
    }

    // ================= USER FUNCTIONS =================

    function colorPixel(uint256 x, uint256 y, bytes3 color) external {
        require(availablePixels(msg.sender) > 0, "Insufficient reputation");
        require(isColorable(x, y), "Cannot color this pixel");

        address owner_ = owners[x][y];
        if (owner_ == address(0)) {
            allPixels.push(Pixel(x, y));
        } else {
            totalUserPixels[owner_]--;
        }
        owners[x][y] = msg.sender;
        colors[x][y] = color;
        totalUserPixels[msg.sender]++;

        emit PixelColored(msg.sender, Pixel(x, y), color);
    }

    function clearPixel(uint256 x, uint256 y) external {
        require(isClearable(x, y), "Cannot clear this pixel");

        address owner_ = owners[x][y];
        totalUserPixels[owner_]--;
        owners[x][y] = address(0);
        colors[x][y] = bytes3(0);

        emit PixelCleared(msg.sender, Pixel(x, y));
    }

    // ================= PUBLIC FUNCTIONS =================

    function totalPixels() public view returns (uint256) {
        return allPixels.length;
    }

    function userReputation(address user) public view returns (uint256) {
        return soulContract.getReputation(user);
    }

    function isColorable(uint256 x, uint256 y) public view returns (bool) {
        address owner_ = owners[x][y];
        return (owner_ == address(0)) || (userReputation(owner_) / pixelCost < totalUserPixels[owner_]);
    }

    function isClearable(uint256 x, uint256 y) public view returns (bool) {
        address owner_ = owners[x][y];
        return (owner_ == msg.sender) || (userReputation(owner_) / pixelCost < totalUserPixels[owner_]);
    }

    function availablePixels(address user) public view returns (uint256) {
        if (userReputation(user) / pixelCost > totalUserPixels[user]) {
            return userReputation(user) / pixelCost - totalUserPixels[user];
        } else {
            return 0;
        }
    }
}
