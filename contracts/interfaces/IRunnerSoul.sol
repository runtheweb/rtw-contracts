// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../erc/ISoulBound721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMissionFactory.sol";

struct Soul {
    uint256 reputation;
    uint256 soulPrice;
}

interface IRunnerSoul is ISoulBound721 {
    // -- state
    function soulPrice() external view returns (uint256); // price of soul mint
    function rtw() external view returns (IERC20); // rtw token address
    function treasury() external view returns (address); // treasury address
    function liquidationFee() external view returns (uint32); // liquidation fee which goes to treasury
    function factory() external view returns (IMissionFactory); // mission factory address
    function souls(address runner) external view returns (Soul memory); // get Soul by address
    // -- owner
    function setSoulPrice(uint256 _soulPrice) external; // set price of soul mint
    function changeLiquidationFee(uint32 _liquidationFee) external; // change liquidation fee
    // -- user
    function tokenURI(uint256 id) external pure returns (string memory); // always returns ""
    function mintSoul() external; // pledge RTW and mint soul bound soul
    function burnSoul() external; // burn soul and return collateral in RTW
    function liquidateSoul(address runner) external; // liquidate soul if reputation = 0
    // -- special
    function increaseReputation(address runner, uint256 amount) external; // only for mission contract
    function decreaseReputation(address runner, uint256 amount) external; // only for mission contract
    // -- public
    function getMySoulId() external view returns (uint256); // get soul id if exists
    function getReputation(address runner) external view returns (uint256); // get runner's reputation
}
