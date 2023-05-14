// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IMissionFactory.sol";

enum MissionStatus {
    NONE, // doesn't exit
    CREATED, // exists
    INITIALIZED, // vrf called
    STARTED, // roles distributed and started
    ENDED // ended
}

struct Position {
    uint256 id;
    uint256 pledgeAmount;
    uint256 pledgeReputation;
    Role role;
}

enum Role {
    NONE,
    COURIER,
    ARBITER
}

struct RequestStatus {
    bool fulfilled; // whether the request has been successfully fulfilled
    bool exists; // whether a requestId exists
    uint256[] randomWords;
}

interface IMission {
    // -- state
    function codex() external view returns (string memory); // mission codex (text / link)
    function totalRewardAmount() external view returns (uint256); // total reward for runners
    function totalOperationAmount() external view returns (uint256); // amount of operation token to operate
    function minTotalCollateralPledge() external view returns (uint256); // min total collateral to start mission
    function operationToken() external view returns (address); // operation token address
    function numberOfCouriers() external view returns (uint32); // number of couriers to choose
    function numberOfArbiters() external view returns (uint32); // number of arbiters to choose
    function executionTime() external view returns (uint32); // duration of couriers period
    function ratingTime() external view returns (uint32); // duration of arbiters period
    function factory() external view returns (IMissionFactory); // mission factory address
    function creator() external view returns (address); // mission creator address
    function status() external view returns (MissionStatus); // mission global state
    function startTime() external view returns (uint256); // time of mission start
    function positions(address runner) external view returns (Position memory); // runner info
    function runners(uint256 id) external view returns (address); // list of joined runners
    function couriers(uint256 id) external view returns (address); // list of couriers after start
    function arbiters(uint256 id) external view returns (address); // list of arbiters after start
    function proofs(address courier) external view returns (string memory); // courier's proofs of their work
    function rates(address arbiter) external view returns (bool); // arbiter's rates of couriers
    function lastRequest() external view returns (RequestStatus memory); // vrf request struct
    function lastRequestId() external view returns (uint256); // vrf request id
    // -- runners
    function joinMission(uint256 _pledgeAmount, uint256 _pledgeReputation) external; // join mission and pledge rtw or reputation
    function leaveMission() external; // leave mission if you are not a courier nor arbiter
    function withdrawCollateral() external; // withdraw collateral and receive mission reward
    // -- owner
    function initMission() external; // call VRF
    function startMission() external; // distribute roles and start
    function endMission() external; // punish and reward runners
    // -- couriers
    function takeOperationTokens() external; // courier receive operation tokens
    function pushProof(string memory proof) external; // courier pushes proof of his work
    // -- arbiters
    function rateCouriers(bool[] memory _rates) external; // abiter rates each courier
    // -- public
    function minRunnerCollateral() external view returns (uint256); // min collateral per runner to join
    function courierOperationAmount() external view returns (uint256); // operation amount per courier
    function runnerRewardAmount() external view returns (uint256); // granted reward per runner
    function totalRunners() external view returns (uint256); // total number of runners joined
    function isCourier(address runner) external view returns (bool); // is the runner an arbiter or not
    function isArbiter(address runner) external view returns (bool); // is the runner an arbiter or not
    function runnerResult(address runner) external view returns (bool res_); // shall a runner be punished or not
    // -- vrf
    function testFulfillRandomWords(uint256[] memory _randomWords) external; // artificially fulfill random request (on test purposes)
}
