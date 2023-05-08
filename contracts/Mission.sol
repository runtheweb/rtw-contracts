// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMissionFactory.sol";
import "./interfaces/IMission.sol";
import "./interfaces/IRunnerSoul.sol";

contract Mission {
    event RunnerJoined(address indexed mission, address indexed runner);
    event RunnerLeaved(address indexed mission, address indexed runner);

    string public codex; // link or text of the mission codex
    uint256 public totalRewardAmount; // amount of RTW token to reward runners
    address public operationToken; // address of an operation token
    uint256 public totalOperationAmount; // amount of the operation token to do something
    uint256 public minTotalCollateralPledge; // min total collateral in RTW required
    uint256 public numberOfCouriers; // required number of couriers to start
    uint256 public numberOfArbiters; // required number of arbiters to start
    uint256 public executionTime; // time couriers to run
    uint256 public ratingTime; // time arbiters to vote

    IMissionFactory public factory; // misstion factory contract
    IERC20 public rtw;
    IRunnerSoul public soulContract; // courierSoul contract

    MissionStatus public status;

    mapping(address => Position) public positions; // runners positions
    address[] public runners;
    uint256 public totalCouriers;
    uint256 public totalArbiters;

    constructor(
        string memory _codex,
        uint256 _totalRewardAmount,
        address _operationToken,
        uint256 _totalOperationAmount,
        uint256 _minTotalCollateralPledge,
        uint256 _numberOfCouriers,
        uint256 _numberOfArbiters,
        uint256 _executionTime,
        uint256 _ratingTime
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
        soulContract = IRunnerSoul(factory.soulContract());
        rtw = factory.rtw();

        status = MissionStatus.CREATED;
    }

    // ================= RUNNER FUNCTIONS =================

    function joinMission(uint256 _pledgeAmount, uint256 _pledgeReputation, Role _role) external {
        require(
            _pledgeAmount + _pledgeReputation >= minRunnerCollateral(), "Cannot pledge less than minRunnerCollateral"
        );
        require(soulContract.balanceOf(msg.sender) > 0, "Cannot join without runner soul");
        require(status == MissionStatus.CREATED, "Cannot join this mission");

        rtw.transferFrom(msg.sender, address(this), _pledgeAmount);
        soulContract.decreaseReputation(msg.sender, _pledgeReputation); // decrease reputation until mission finish

        if (_role == Role.COURIER) {
            totalCouriers++;
        } else {
            totalArbiters++;
        }

        positions[msg.sender] = Position(totalRunners(), _pledgeAmount, _pledgeReputation, _role);
        runners.push(msg.sender);

        emit RunnerJoined(address(this), msg.sender);
    }

    function leaveMission() external {
        Position storage position = positions[msg.sender];
        require(position.id > 0, "Runner did not join");

        if (status == MissionStatus.CREATED) {
            rtw.transfer(msg.sender, position.pledgeAmount);
            soulContract.increaseReputation(msg.sender, position.pledgeReputation);
        } else if (status == MissionStatus.ENDED) {
            // todo: add logic to withdraw
        }

        uint256 ind_ = position.id - 1;

        runners[ind_] = runners[totalRunners() - 1];
        runners.pop();
        // change index of the last collateral which was moved
        if (runners.length != ind_) {
            positions[runners[ind_]].id = ind_ + 1;
        }

        delete positions[msg.sender];

        if (position.role == Role.COURIER) {
            totalCouriers--;
        } else {
            totalArbiters--;
        }

        emit RunnerLeaved(address(this), msg.sender);
    }

    function withdrawCollateral() external {}
    // -- owner
    function initMission() external {}
    function startMission() external {}
    function endMission() external {}
    // -- couriers
    function takeOperationTokens() external {}
    function pushProof(string memory proof) external {}
    // -- arbiters
    function rateCouriers(bool[] memory rates) external {}

    // ================= PUBLIC FUNCTIONS =================

    function minRunnerCollateral() public view returns (uint256) {
        return minTotalCollateralPledge / numberOfCouriers;
    }

    function runnerOperationAmount() public view returns (uint256) {
        return totalOperationAmount / numberOfCouriers;
    }

    function totalRunners() public view returns (uint256) {
        return totalCouriers + totalArbiters;
    }
}
