// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/IMissionFactory.sol";
import "./interfaces/IMission.sol";
import "./interfaces/IRunnerSoul.sol";

contract Mission is VRFConsumerBaseV2(address(IMissionFactory(msg.sender).vrfCoordinator())) {
    event RunnerJoined(address indexed runner);
    event RunnerLeaved(address indexed runner);
    event MissionInitialized();
    event MissionStarted();
    event CourierTookTokens(address indexed courier);
    event CourierPushedProof(address indexed courier, string proof);
    event ArbiterRated(address indexed arbiter, bool[] rates);
    event MissionEnded();
    event CollateralWithdrawed(address indexed runner);

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    string public codex; // link or text of the mission codex
    uint256 public totalRewardAmount; // amount of RTW token to reward runners
    uint256 public totalOperationAmount; // amount of the operation token to do something
    uint256 public minTotalCollateralPledge; // min total collateral in RTW required
    address public operationToken; // address of an operation token

    uint32 public numberOfCouriers; // required number of couriers to start
    uint32 public numberOfArbiters; // required number of arbiters to start
    uint32 public executionTime; // time couriers to run
    uint32 public ratingTime; // time arbiters to vote

    IMissionFactory public factory; // misstion factory contract

    address public creator; // mission creator

    MissionStatus public status;
    uint256 public startTime;

    mapping(address => Position) public positions; // runners positions
    address[] public runners; // all runners
    address[] public couriers; // only couriers
    address[] public arbiters; // only arbiters

    mapping(address => string) public proofs; // courier proofs
    mapping(address => bool[]) public rates; // arbiters rates of couriers
    uint256[] internal couriersRates; // total rates of couriers
    uint256 internal totalRates; // total rated arbiters

    // vrf params
    RequestStatus public lastRequest; // vrf requests
    uint256 public lastRequestId;

    constructor(
        string memory _codex,
        uint256 _totalRewardAmount,
        uint256 _totalOperationAmount,
        uint256 _minTotalCollateralPledge,
        address _operationToken,
        uint32 _numberOfCouriers,
        uint32 _numberOfArbiters,
        uint32 _executionTime,
        uint32 _ratingTime,
        address _creator
    ) {
        codex = _codex;
        totalRewardAmount = _totalRewardAmount;
        operationToken = _operationToken;
        totalOperationAmount = _totalOperationAmount;
        minTotalCollateralPledge = _minTotalCollateralPledge;
        numberOfCouriers = _numberOfCouriers;
        numberOfArbiters = _numberOfArbiters;
        executionTime = _executionTime;
        ratingTime = _ratingTime;

        factory = IMissionFactory(msg.sender);
        creator = _creator;

        status = MissionStatus.CREATED;
    }

    // ================= RUNNER FUNCTIONS =================

    function joinMission(uint256 _pledgeAmount, uint256 _pledgeReputation) external {
        require(
            _pledgeAmount + _pledgeReputation >= minRunnerCollateral(), "Cannot pledge less than minRunnerCollateral"
        );
        require(factory.soulContract().balanceOf(msg.sender) > 0, "Cannot join without runner soul");
        require(status == MissionStatus.CREATED, "Status mismatch");

        factory.rtw().burn(msg.sender, _pledgeAmount);
        factory.soulContract().decreaseReputation(msg.sender, _pledgeReputation); // decrease reputation until mission finish

        runners.push(msg.sender);

        positions[msg.sender] = Position(totalRunners(), _pledgeAmount, _pledgeReputation, Role.NONE);

        emit RunnerJoined(msg.sender);
    }

    function leaveMission() external {
        Position storage position = positions[msg.sender];
        require(position.id > 0, "Runner did not join");

        bool hasRole_ = isCourier(msg.sender) || isArbiter(msg.sender);

        require(
            status == MissionStatus.CREATED
                || ((status == MissionStatus.STARTED || status == MissionStatus.ENDED) && !hasRole_),
            "Cannot withdraw until mission end"
        );

        factory.rtw().mint(msg.sender, position.pledgeAmount);
        factory.soulContract().increaseReputation(msg.sender, position.pledgeReputation);

        uint256 ind_ = position.id - 1;

        runners[ind_] = runners[totalRunners() - 1];
        runners.pop();
        // change index of the last collateral which was moved
        if (runners.length != ind_) {
            positions[runners[ind_]].id = ind_ + 1;
        }

        delete positions[msg.sender];

        emit RunnerLeaved(msg.sender);
    }

    function withdrawCollateral() external {
        require(status == MissionStatus.ENDED, "State mismatch");
        Position memory position_ = positions[msg.sender];

        bool res_ = runnerResult(msg.sender);
        require(res_, "Loosers cannot withdraw");

        factory.rtw().transfer(msg.sender, runnerRewardAmount());

        factory.rtw().mint(msg.sender, position_.pledgeAmount);
        uint256 rewardReputation_ = position_.pledgeReputation * factory.extraReputation() / 1e8;
        factory.soulContract().increaseReputation(msg.sender, position_.pledgeReputation + rewardReputation_);

        // mint reward token if not minted
        uint256 tokenId_ = factory.rewardToken().getIdByMissionAddress(address(this));
        if (factory.rewardToken().balanceOf(msg.sender, tokenId_) == 0) {
            factory.rewardToken().mintRewardToken(msg.sender, IMission(address(this)));
        }

        delete positions[msg.sender];

        emit CollateralWithdrawed(msg.sender);
    }

    // ================= GENERAL FUNCTIONS =================

    /**
     * @notice Initialize mission to prepare to start
     * @dev Call vrf and stop enering and exiting of runners
     */
    function initMission() external {
        require(status == MissionStatus.CREATED, "State mismatch");
        require(runners.length >= numberOfArbiters + numberOfCouriers, "Insufficient runners");
        require(msg.sender == creator, "Only mission creator can initialize");

        status = MissionStatus.INITIALIZED;
        _requestRandomWords();

        emit MissionInitialized();
    }

    function startMission() external {
        require(status == MissionStatus.INITIALIZED, "State mismatch");
        require(lastRequest.fulfilled, "Initialization is not completed");

        status = MissionStatus.STARTED;
        startTime = block.timestamp;
        address[] memory shuffledRunners_ = _shuffleRunners();

        for (
            uint256 i = shuffledRunners_.length - numberOfCouriers - numberOfArbiters; i < shuffledRunners_.length; ++i
        ) {
            Position storage position_ = positions[shuffledRunners_[i]];
            if (i < shuffledRunners_.length - numberOfArbiters) {
                position_.role = Role.COURIER;
                couriers.push(shuffledRunners_[i]);
            } else {
                position_.role = Role.ARBITER;
                arbiters.push(shuffledRunners_[i]);
            }
        }

        couriersRates = new uint256[](couriers.length);

        emit MissionStarted();
    }

    function _shuffleRunners() internal view returns (address[] memory) {
        address[] memory arr = runners;
        uint256 i = arr.length;
        uint256 randNum = lastRequest.randomWords[0];
        while (i != arr.length - numberOfCouriers - numberOfArbiters) {
            uint256 r = uint256(keccak256(abi.encode(randNum, i))) % i;
            address elem = arr[r];
            arr[r] = arr[i - 1];
            arr[i - 1] = elem;
            i--;
        }
        return arr;
    }

    function endMission() external {
        require(status == MissionStatus.STARTED, "State missmatch");
        require(startTime + executionTime + ratingTime < block.timestamp, "Mission time is not over yet");

        uint32 totalCourierLoosers_;
        uint32 totalArbitersLoosers_;
        for (uint256 i = 0; i < couriers.length; ++i) {
            totalCourierLoosers_ += _getCourierResult(couriers[i]) ? 0 : 1;
        }
        for (uint256 i = 0; i < arbiters.length; ++i) {
            totalArbitersLoosers_ += _getArbiterResult(arbiters[i]) ? 0 : 1;
        }

        status = MissionStatus.ENDED;

        // transfer unused reward to treasury
        uint256 unusedReward_ = runnerRewardAmount() * (totalCourierLoosers_ + totalArbitersLoosers_);
        factory.rtw().transfer(factory.treasury(), unusedReward_);

        // compensate losses by courier liquidation
        uint256 compensation_ = totalCourierLoosers_ * minRunnerCollateral();
        uint256 fee_ = compensation_ * factory.treasuryFee() / 1e8;
        factory.rtw().mint(creator, compensation_ - fee_);

        // rest from arbiters liquidation goes to treasury
        uint256 rest_ = totalArbitersLoosers_ * minRunnerCollateral();
        factory.rtw().mint(factory.treasury(), rest_ + fee_);

        emit MissionEnded();
    }

    function _computeCouriers() internal view returns (bool[] memory) {
        bool[] memory results_ = new bool[](couriersRates.length);
        for (uint256 i = 0; i < results_.length; ++i) {
            results_[i] = couriersRates[i] * 10 > totalRates * 10 / 2; // times 10 to avoid rounding
        }
        return results_;
    }

    function _getCourierResult(address _courier) internal view returns (bool res_) {
        bool[] memory results_ = _computeCouriers();
        for (uint256 i = 0; i < couriers.length; ++i) {
            if (couriers[i] == _courier) {
                res_ = results_[i];
                break;
            }
        }
    }

    function _getArbiterResult(address _arbiter) internal view returns (bool) {
        bool[] memory results_ = _computeCouriers();
        bool[] memory rate_ = rates[_arbiter];

        // punish if didn't vote
        if (rate_.length == 0) {
            return false;
        }

        uint256 majorityMatch_;
        for (uint256 i = 0; i < numberOfCouriers; ++i) {
            majorityMatch_ += results_[i] == rate_[i] ? 1 : 0;
        }
        return majorityMatch_ * 100 / totalRates > 90;
    }

    // ================= COURIERS FUNCTIONS =================

    function takeOperationTokens() external {
        require(status == MissionStatus.STARTED, "State missmatch");
        require(startTime + executionTime >= block.timestamp, "Courier time is over");
        require(isCourier(msg.sender), "Not courier");

        uint256 amount_ = courierOperationAmount();
        IERC20(operationToken).transfer(msg.sender, amount_);

        emit CourierTookTokens(msg.sender);
    }

    function pushProof(string memory proof) external {
        require(status == MissionStatus.STARTED, "State missmatch");
        require(startTime + executionTime >= block.timestamp, "Courier time is over");
        require(isCourier(msg.sender), "Not courier");

        proofs[msg.sender] = proof;

        emit CourierPushedProof(msg.sender, proof);
    }

    // ================= ARBITERS FUNCTIONS =================

    function rateCouriers(bool[] memory _rates) external {
        require(status == MissionStatus.STARTED, "State missmatch");
        require(startTime + executionTime < block.timestamp, "Arbiters time has not come yet");
        require(startTime + executionTime + ratingTime >= block.timestamp, "Arbiters time is over");
        require(isArbiter(msg.sender), "Not arbiter");
        require(_rates.length == numberOfCouriers, "Too much or too low rates");
        require(rates[msg.sender].length == 0, "Cannot revote");

        for (uint256 i = 0; i < _rates.length; ++i) {
            couriersRates[i] += _rates[i] ? 1 : 0;
        }

        rates[msg.sender] = _rates;
        totalRates++;

        emit ArbiterRated(msg.sender, _rates);
    }

    // ================= PUBLIC FUNCTIONS =================

    function minRunnerCollateral() public view returns (uint256) {
        return minTotalCollateralPledge / numberOfCouriers;
    }

    function courierOperationAmount() public view returns (uint256) {
        return totalOperationAmount / numberOfCouriers;
    }

    function runnerRewardAmount() public view returns (uint256) {
        return totalRewardAmount / (numberOfCouriers + numberOfArbiters);
    }

    function totalRunners() public view returns (uint256) {
        return runners.length;
    }

    function isCourier(address runner) public view returns (bool) {
        return positions[runner].role == Role.COURIER;
    }

    function isArbiter(address runner) public view returns (bool) {
        return positions[runner].role == Role.ARBITER;
    }

    function runnerResult(address runner) public view returns (bool res_) {
        require(status == MissionStatus.ENDED, "Mission is not ended yet");

        Role role_ = positions[runner].role;
        if (role_ == Role.COURIER) {
            res_ = _getCourierResult(runner);
        } else if (role_ == Role.ARBITER) {
            res_ = _getArbiterResult(runner);
        } else {
            revert("Is not a runner");
        }
    }

    // ================= VRF CONSUMER FUNCTIONS =================

    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords() internal returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = factory.vrfCoordinator().requestRandomWords(
            0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15, factory.subscriptionId(), 3, 2500000, 1
        );
        lastRequest = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        lastRequestId = requestId;
        emit RequestSent(requestId, 1);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(lastRequest.exists, "request not found");
        lastRequest.fulfilled = true;
        lastRequest.randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    /**
     * @notice Artificially fulfill ctf request
     * @dev Public only due to testnet testing in case if chainlink doesn't response
     */
    function testFulfillRandomWords(uint256[] memory _randomWords) public {
        require(msg.sender == creator, "only creator");
        require(lastRequest.exists, "request not found");
        lastRequest.fulfilled = true;
        lastRequest.randomWords = _randomWords;
        emit RequestFulfilled(lastRequestId, _randomWords);
    }
}
