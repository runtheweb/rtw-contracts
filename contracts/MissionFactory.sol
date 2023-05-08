// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Mission.sol";

contract MissionFactory is Ownable {
    event MissionCreated(address indexed missionAddress, address indexed creatorAddress);

    IERC20 public rtw; // RTW token
    address public soulContract;
    address[] public missionList; // list of created missions addresses
    mapping(address => uint256) public missionIds; // mission ids starts from 1
    uint256 public totalMissions; // total number of created missions

    // ================= OWNER FUNCTIONS =================

    /**
     * @notice Initialize contract dependencies
     * @dev Reinitialization available only for test purposes
     */
    function initialize(IERC20 _rtw) external onlyOwner {
        // require(rtx == address(0) && _rtx != address(0), "Already initialized");
        rtw = _rtw;
    }

    // ================= USER FUNCTIONS =================

    function createMission(
        string memory _codex,
        uint256 _totalRewardAmount,
        address _operationToken,
        uint256 _totalOperationAmount,
        uint256 _minTotalCollateralPledge,
        uint256 _numberOfCouriers,
        uint256 _numberOfArbiters,
        uint256 _executionTime,
        uint256 _ratingTime
    )
        external
    {
        Mission mission = new Mission(
            _codex,
            _totalRewardAmount,
            _operationToken,
            _totalOperationAmount,
            _minTotalCollateralPledge,
            _numberOfCouriers,
            _numberOfArbiters,
            _executionTime,
            _ratingTime
        );

        // transfer operation token
        IERC20(_operationToken).transferFrom(msg.sender, address(mission), _totalOperationAmount);
        // transfer mission reward
        IERC20(rtw).transferFrom(msg.sender, address(mission), _totalRewardAmount);

        totalMissions++;
        missionList.push(address(mission));
        missionIds[address(mission)] = totalMissions;

        emit MissionCreated(address(mission), msg.sender);
    }

    // ================= SPECIAL FUNCTIONS =================

    // ================= INTERNAL FUNCTIONS =================
}
