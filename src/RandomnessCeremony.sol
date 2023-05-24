// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/utils/Counters.sol";

struct Randomness
{
    bytes32 randomBytes;
    uint commitmentDeadline;
    uint revealDeadline;
    bool rewardIsClaimed;
    uint stakeAmount;
    address creator;
}

contract RandomnessCeremony {
    using Counters for Counters.Counter;
    enum CommitmentState {NotCommitted, Committed, Revealed, Slashed}

    function sendETH(address payable _to, uint amount) internal {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        data;
        require(sent, "Failed to send Ether");
    }

    struct Commitment
    {
        address committer;
        CommitmentState state;
    }

    Counters.Counter public randomnessIds;
    mapping(uint randomnessId => Randomness) public randomness;
    mapping(uint randomnessId => mapping(bytes32 hashedValue => Commitment commitment)) public commitments;

    constructor() {
    }

    // Public Functions

    function commit(address committer, uint randomnessId, bytes32 hashedValue) public payable {
        require(msg.value == randomness[randomnessId].stakeAmount, "Invalid stake amount");
        require(block.timestamp <= randomness[randomnessId].commitmentDeadline, "Can't commit at this moment.");
        commitments[randomnessId][hashedValue] = Commitment(committer, CommitmentState.Committed);
    }

    function reveal(uint randomnessId, bytes32 hashedValue, bytes32 secretValue) public {
        require(block.timestamp > randomness[randomnessId].commitmentDeadline &&
            block.timestamp <= randomness[randomnessId].revealDeadline, "Can't reveal at this moment.");
        require(commitments[randomnessId][hashedValue].state == CommitmentState.Committed, "Hash is not commited");
        require(hashedValue == keccak256(abi.encodePacked(secretValue)), "Invalid secret value");

        commitments[randomnessId][hashedValue].state = CommitmentState.Revealed;

        randomness[randomnessId].randomBytes = randomness[randomnessId].randomBytes ^ secretValue;

        sendETH(
            payable(commitments[randomnessId][hashedValue].committer),
            randomness[randomnessId].stakeAmount
        );
    }

    function getRandomness(uint randomnessId) public view returns(bytes32) {
        require(block.timestamp > randomness[randomnessId].revealDeadline,
            "Randomness not ready yet.");
        return randomness[randomnessId].randomBytes;
    }

    function generateRandomness(uint commitmentDeadline, uint revealDeadline, uint stakeAmount) public returns(uint){
        uint randomnessId = randomnessIds.current();
        randomness[randomnessId] = Randomness(
            bytes32(0),
            commitmentDeadline,
            revealDeadline,
            false,
            stakeAmount,
            msg.sender
        );
        randomnessIds.increment();
        return randomnessId;
    }

    function claimSlashedETH(uint randomnessId, bytes32 hashedValue) public {
        require(randomness[randomnessId].creator == msg.sender, "Only creator can claim slashed");
        require(block.timestamp > randomness[randomnessId].revealDeadline, "Slashing period has not happened yet");
        require(commitments[randomnessId][hashedValue].state == CommitmentState.Committed, "This commitment was not slashed");
        commitments[randomnessId][hashedValue].state = CommitmentState.Slashed;
        sendETH(
            payable(msg.sender),
            randomness[randomnessId].stakeAmount
        );
    }
}