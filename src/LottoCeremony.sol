// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Counters.sol";
import "./RandomnessCeremony.sol";

contract LottoCeremony is Ownable {

    using Counters for Counters.Counter;
    RandomnessCeremony randomnessCeremony;

    function sendETH(address payable _to, uint amount) public {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        data;
        require(sent, "Failed to send Ether");
    }

    struct Ceremony {
        uint randomnessCeremonyId;
        bool isClaimed;
        uint ticketCount;
        uint ticketPrice;
        uint stakeAmount;
    }

    Counters.Counter private ceremonyCount;
    mapping(uint ceremonyId => Ceremony) public ceremonies;
    mapping(uint ceremonyId => mapping(uint ticketId => address ticketOwner)) public tickets;

    constructor(address randomnessCeremonyAddress) {
        randomnessCeremony = RandomnessCeremony(payable(randomnessCeremonyAddress));
    }

    function createCeremony(
        uint commitmentDeadline,
        uint revealDeadline,
        uint ticketPrice,
        uint stakeAmount) public {
        uint randomnessCeremonyId = randomnessCeremony.generateRandomness(
            commitmentDeadline,
            revealDeadline,
            stakeAmount);
        ceremonies[ceremonyCount.current()] = Ceremony(
            randomnessCeremonyId,
            false,
            0,
            ticketPrice,
            stakeAmount);
        ceremonyCount.increment();
    }

    function commit(address commiter, uint ceremonyId, bytes32 hashedValue) public payable {
        Ceremony memory ceremony = ceremonies[ceremonyId];
        require(msg.value == ceremony.ticketPrice + ceremony.stakeAmount);
        randomnessCeremony.commit{value: ceremony.stakeAmount}(commiter, ceremony.randomnessCeremonyId, hashedValue);
        tickets[ceremonyId][ceremony.ticketCount] = commiter;
        ceremonies[ceremonyId].ticketCount += 1;
    }

    function reveal(uint ceremonyId, bytes32 hashedValue, bytes32 secretValue) public /** TODO Reentrancy */ {
        randomnessCeremony.reveal(ceremonies[ceremonyId].randomnessCeremonyId, hashedValue, secretValue);
    }

    function claimSlashedETH(uint randomnessCeremonyId, bytes32 hashedValue) public /** Slashed eth nao wat */  {
        randomnessCeremony.claimSlashedETH(randomnessCeremonyId, hashedValue);
    }

    function claim(uint ceremonyId) public {
        Ceremony memory ceremony = ceremonies[ceremonyId];
        require(!ceremony.isClaimed, "Already claimed");
        ceremony.isClaimed = true;
        uint randomness = uint(randomnessCeremony.getRandomness(ceremonyId));
        uint randomTicket = randomness % ceremony.ticketCount;
        address winner = tickets[ceremonyId][randomTicket];
        sendETH(
            payable(winner),
            ceremony.ticketPrice * ceremony.ticketCount
        );
    }
}