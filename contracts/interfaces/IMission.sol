// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum MissionStatus {
    NONE,
    CREATED,
    INITIALIZED,
    STARTED,
    ENDED
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
    // -- runners
    function joinMission(uint256 pledgeAmount, uint256 pledgeReputation, Role role) external;
    function leaveMission() external;
    function withdrawCollateral() external; // after mission
    // -- owner
    function initMission() external; // call VRF
    function startMission() external; // distribute roles and start
    function endMission() external; // punish and reward runners
    // -- couriers
    function takeOperationTokens() external;
    function pushProof(string memory proof) external; // couriers provide proofs
    // -- arbiters
    function rateCouriers(bool[] memory rates) external; // rates for each courier
    // -- view
    function runnerResult(address runner) external view returns (bool);
}
