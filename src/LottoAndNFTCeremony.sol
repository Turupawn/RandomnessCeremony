// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Counters.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "./RandomnessCeremony.sol";

contract LottoAndNFTCeremony is Ownable {

    using Counters for Counters.Counter;
    RandomnessCeremony public randomnessCeremony;

    function sendETH(address payable _to, uint amount) internal {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        data;
        require(sent, "Failed to send Ether");
    }

    struct Ceremony {
        uint randomnessCeremonyId;
        bool isETHClaimed;
        bool isNFTClaimed;
        uint ticketCount;
        uint ticketPrice;
        uint stakeAmount;
        address nftContractAddress;
        uint nftID;
    }

    Counters.Counter public ceremonyCount;
    mapping(uint ceremonyId => Ceremony) public ceremonies;
    mapping(uint ceremonyId => mapping(uint ticketId => address ticketOwner)) public tickets;

    constructor(address randomnessCeremonyAddress) {
        randomnessCeremony = RandomnessCeremony(payable(randomnessCeremonyAddress));
    }

    // Public functions

    function createCeremony(
        uint commitmentDeadline,
        uint revealDeadline,
        uint ticketPrice,
        uint stakeAmount,
        address nftContractAddress,
        uint nftID) public {
        uint randomnessCeremonyId = randomnessCeremony.generateRandomness(
            commitmentDeadline,
            revealDeadline,
            stakeAmount);
        IERC721(nftContractAddress).transferFrom(msg.sender, address(this), 0);
        ceremonies[ceremonyCount.current()] = Ceremony(
            randomnessCeremonyId,
            false,
            false,
            0,
            ticketPrice,
            stakeAmount,
            nftContractAddress,
            nftID);
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

    function claimETH(uint ceremonyId) public {
        Ceremony memory ceremony = ceremonies[ceremonyId];
        require(!ceremony.isETHClaimed, "Already claimed");
        ceremony.isETHClaimed = true;
        address winner = getWinner(ceremonyId, WinnerType.ETHWinner);
        sendETH(
            payable(winner),
            ceremony.ticketPrice * ceremony.ticketCount
        );
    }

    function claimNFT(uint ceremonyId) public {
        Ceremony memory ceremony = ceremonies[ceremonyId];
        require(!ceremony.isNFTClaimed, "Already claimed");
        ceremony.isNFTClaimed = true;
        address winner = getWinner(ceremonyId, WinnerType.NFTWinner);
        IERC721(ceremony.nftContractAddress).transferFrom(address(this), winner, 0);
    }

    // Creator functions

    function claimSlashedETH(uint randomnessCeremonyId, bytes32 hashedValue) public /** Slashed eth nao wat */  {
        randomnessCeremony.claimSlashedETH(randomnessCeremonyId, hashedValue);
    }

    // View functions
    enum WinnerType
    {
        ETHWinner,
        NFTWinner,
        BeerRoundLooser
    }

    function getWinner(uint ceremonyId, WinnerType winnerType) public view returns(address) {
        uint randomness = uint(getRandomness(ceremonyId));
        uint winnerRandomness = uint(keccak256(abi.encode(randomness, winnerType)));
        uint randomTicket = winnerRandomness % ceremonies[ceremonyId].ticketCount;
        return tickets[ceremonyId][randomTicket];
    }

    function getRandomness(uint ceremonyId) public view returns(uint) {
        return uint(randomnessCeremony.getRandomness(ceremonyId));
    }
}