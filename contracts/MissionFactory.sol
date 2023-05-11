// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRtwToken.sol";
import "./interfaces/IRewardToken.sol";
import "./Mission.sol";

contract MissionFactory is Ownable {
    event MissionCreated(address indexed missionAddress, address indexed creatorAddress);

    IRtwToken public rtw; // RTW token
    IRunnerSoul public soulContract;
    LinkTokenInterface public linkToken;
    VRFCoordinatorV2Interface public vrfCoordinator;
    IRewardToken public rewardToken;

    address public treasury; // treasury to collect rewards

    address[] public missionList; // list of created missions addresses
    mapping(address => uint64) public missionIds; // mission ids starts from 1
    uint64 public totalMissions; // total number of created missions
    uint64 public subscriptionId; // vrf subscriptionId

    uint32 public constant MAX_TREASURY_FEE = 1e8; // 100%
    uint32 public treasuryFee;

    uint32 public constant MAX_EXTRA_REPUTATION = 1e8; // 100%
    uint32 public extraReputation; // extra reputation reward for success mission

    constructor(uint32 _treasuryFee, uint32 _extraReputation) {
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
        IRtwToken _rtw,
        IRunnerSoul _soulContract,
        LinkTokenInterface _linkToken,
        VRFCoordinatorV2Interface _vrfCoordinator,
        IRewardToken _rewardToken,
        address _treasury
    )
        external
        onlyOwner
    {
        rtw = _rtw;
        soulContract = _soulContract;
        linkToken = _linkToken;
        vrfCoordinator = _vrfCoordinator;
        rewardToken = _rewardToken;
        treasury = _treasury;
    }

    function createSubscription() external onlyOwner {
        uint64 subId_ = vrfCoordinator.createSubscription();
        subscriptionId = subId_;
    }

    function fundSubscription(uint256 _linkAmount) external onlyOwner {
        linkToken.transferAndCall(address(vrfCoordinator), _linkAmount, abi.encode(subscriptionId));
    }

    function changeTreasuryFee(uint32 _treasuryFee) external onlyOwner {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Fee cannot exceed MAX_TREASURY_FEE");
        treasuryFee = _treasuryFee;
    }

    function changeExtraReputation(uint32 _extraReputation) external onlyOwner {
        require(_extraReputation <= MAX_EXTRA_REPUTATION, "Extra reputation cannot exceed MAX_EXTRA_REPUTATION");
        extraReputation = _extraReputation;
    }

    // ================= USER FUNCTIONS =================

    function createMission(
        string memory _codex,
        uint256 _totalRewardAmount,
        uint256 _totalOperationAmount,
        uint256 _minTotalCollateralPledge,
        address _operationToken,
        uint32 _numberOfCouriers,
        uint32 _numberOfArbiters,
        uint32 _executionTime,
        uint32 _ratingTime
    )
        external
    {
        uint256 fee_ = _totalRewardAmount * treasuryFee / 1e8;
        rtw.transferFrom(msg.sender, treasury, fee_);

        Mission mission = new Mission(
            _codex,
            _totalRewardAmount - fee_,
            _totalOperationAmount,
            _minTotalCollateralPledge,
            _operationToken,
            _numberOfCouriers,
            _numberOfArbiters,
            _executionTime,
            _ratingTime,
            msg.sender
        );

        // transfer operation token
        IERC20(_operationToken).transferFrom(msg.sender, address(mission), _totalOperationAmount);
        // transfer mission reward
        rtw.transferFrom(msg.sender, address(mission), _totalRewardAmount - fee_);

        totalMissions++;
        missionList.push(address(mission));
        missionIds[address(mission)] = totalMissions;

        // add vrf consumer
        vrfCoordinator.addConsumer(subscriptionId, address(mission));

        emit MissionCreated(address(mission), msg.sender);
    }
}
