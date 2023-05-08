// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc/SoulBound721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/IERC20.sol";
import "interfaces/IRunnerSoul.sol";

contract RunnerSoul is SoulBound, Ownable {
    uint256 public soulPrice; // price of mint a soul
    uint256 public liquidationFee; // treasury fee for liquidation (1e18 = 100%)
    IERC20 public rtw; // RTW token address
    address public treasury; // DAO treasury

    uint256 public constant MAX_LIQUIDATION_FEE = 1e18;

    mapping(address => Soul) public souls;

    // ================= CONSTRUCTOR =================

    constructor(uint256 _soulPrice, uint256 _liquidationFee) SoulBound("Runner Soul", "RSOUL") {
        require(_liquidationFee <= MAX_LIQUIDATION_FEE, "Fee cannot exceed MAX_LIQUIDATION_FEE");
        soulPrice = _soulPrice;
        liquidationFee = _liquidationFee;
    }

    // ================= OWNER FUNCTIONS =================

    /**
     * @notice Initialize contract dependencies
     * @dev Reinitialization available only for test purposes
     */
    function initialize(address _rtw) external onlyOwner {
        // require(rtx == address(0) && _rtx != address(0), "Already initialized");
        rtx = _rtx;
    }

    function setSoulPrice(uint256 _soulPrice) external onlyOwner {
        soulPrice = _soulPrice;
    }

    function changeLiquidationFee(uint256 _liquidationFee) external onlyOwner {
        require(_liquidationFee <= MAX_LIQUIDATION_FEE, "Fee cannot exceed MAX_LIQUIDATION_FEE");
        liquidationFee = _liquidationFee;
    }

    // ================= INTERNAL FUNCTIONS =================

    function _getIdByAddress(address addr) internal pure returns (uint256) {
        return uint256(uint160(addr));
    }

    function _getAddressById(uint256 id) internal pure returns (address) {
        return address(uint160(id));
    }

    // ================= USER FUNCTIONS =================

    function mintSoul() external {
        require(_balanceOf[msg.sender] == 0, "Courier soul already minted");
        rtw.transferFrom(msg.sender, address(this), soulPrice);
        _mint(msg.sender, _getIdByAddress(msg.sender));
        souls[msg.sender] = Soul({reputation: soulPrice, soulPrice: soulPrice});
    }

    function burnSoul() external {
        Soul storage soul = souls[msg.sender];
        require(soul.reputation >= soul.soulPrice, "Cannot burn soul which reputation below initial");
        _burn(_getIdByAddress(msg.sender));
        rtw.transfer(msg.sender, soul.soulPrice);
        delete souls[msg.sender];
    }

    function getReputation(address runner) external returns (uint256) {
        return souls[runner].reputation;
    }

    function liquidateSoul(address runner) external {
        Soul storage soul = souls[runner];
        require(soul.reputation == 0, "Cannot liquidate soul with positive reputation");
        require(_balanceOf[runner] > 0, "Sould is not minted");

        uint256 fee = (soul.soulPrice * liquidationFee) / 1e18;

        _burn(_getIdByAddress(runner));

        rtw.transfer(treasury, fee);
        rtw.transfer(msg.sender, soul.soulPrice - fee);

        delete souls[runner];
    }
}
