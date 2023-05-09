// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Mission.sol";

contract MissionFactory is Ownable {
    event MissionCreated(address indexed missionAddress, address indexed creatorAddress);

    IERC20 public rtw; // RTW token
    IRunnerSoul public soulContract;
    LinkTokenInterface public linkToken;
    VRFCoordinatorV2Interface public vrfCoordinator;
    address public treasury; // treasury to collect rewards

    address[] public missionList; // list of created missions addresses
    mapping(address => uint256) public missionIds; // mission ids starts from 1
    uint256 public totalMissions; // total number of created missions
    uint64 public subscriptionId; // vrf subscriptionId

    uint256 public constant MAX_TREASURY_FEE = 1e18; // 100%
    uint256 public treasuryFee;

    uint256 public constant MAX_EXTRA_REPUTATION = 1e18; // 100%
    uint256 public extraReputation; // extra reputation reward for success mission

    constructor(uint256 _treasuryFee, uint256 _extraReputation) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Fee cannot exceed MAX_TREASURY_FEE");
        require(_extraReputation <= MAX_EXTRA_REPUTATION, "Extra reputation cannot exceed MAX_EXTRA_REPUTATION");
        treasuryFee = _treasuryFee;
        extraReputation = _extraReputation;
    }
    // ================= OWNER FUNCTIONS =================

    /**
     * @notice Initialize contract dependencies
     * @dev Reinitialization available only for test purposes
     */
    function initialize(
        IERC20 _rtw,
        IRunnerSoul _soulContract,
        LinkTokenInterface _linkToken,
        VRFCoordinatorV2Interface _vrfCoordinator,
        address _treasury
    )
        external
        onlyOwner
    {
        rtw = _rtw;
        soulContract = _soulContract;
        linkToken = _linkToken;
        vrfCoordinator = _vrfCoordinator;
        treasury = _treasury;
    }

    function createSubscription(uint256 _linkAmount) external onlyOwner {
        uint64 subId_ = vrfCoordinator.createSubscription();
        linkToken.transferAndCall(address(vrfCoordinator), _linkAmount, abi.encode(subId_));
        subscriptionId = subId_;
    }

    function fundSubscription(uint256 _linkAmount) external onlyOwner {
        linkToken.transferAndCall(address(vrfCoordinator), _linkAmount, abi.encode(subscriptionId));
    }

    function changeTreasuryFee(uint256 _treasuryFee) external onlyOwner {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Fee cannot exceed MAX_TREASURY_FEE");
        treasuryFee = _treasuryFee;
    }

    function changeExtraReputation(uint256 _extraReputation) external onlyOwner {
        require(_extraReputation <= MAX_EXTRA_REPUTATION, "Extra reputation cannot exceed MAX_EXTRA_REPUTATION");
        extraReputation = _extraReputation;
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
            _ratingTime,
            msg.sender
        );

        // transfer operation token
        IERC20(_operationToken).transferFrom(msg.sender, address(mission), _totalOperationAmount);
        // transfer mission reward
        IERC20(rtw).transferFrom(msg.sender, address(mission), _totalRewardAmount);

        totalMissions++;
        missionList.push(address(mission));
        missionIds[address(mission)] = totalMissions;

        // add vrf consumer
        vrfCoordinator.addConsumer(subscriptionId, address(mission));

        emit MissionCreated(address(mission), msg.sender);
    }
}
