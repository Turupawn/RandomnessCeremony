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
        bool isNFTClaimed;
        bool isETHClaimed;
        bool isNFTCreatorETHClaimed;
        bool isProtocolETHClaimed;
        uint ticketCount;
        uint ticketPrice;
        uint stakeAmount;
        uint nftID;
        address nftContractAddress;
        address nftCreatorAddress;
        address protocolAddress;
        Percentages percentages;
    }

    struct Percentages {
        uint lottoETHPercentage;
        uint nftCreatorETHPercentage;
        uint protocolETHPercentage;
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
        uint nftID,
        address nftContractAddress,
        address nftCreatorAddress,
        address protocolAddress,
        uint nftCreatorETHPercentage,
        uint protocolETHPercentage) public {
        uint randomnessCeremonyId = randomnessCeremony.generateRandomness(
            commitmentDeadline,
            revealDeadline,
            stakeAmount);
        IERC721(nftContractAddress).transferFrom(msg.sender, address(this), nftID);
        uint lottoETHPercentage = 10000 - nftCreatorETHPercentage - protocolETHPercentage;
        ceremonies[ceremonyCount.current()] = Ceremony(
            randomnessCeremonyId,
            false,
            false,
            false,
            false,
            0,
            ticketPrice,
            stakeAmount,
            nftID,
            nftContractAddress,
            nftCreatorAddress,
            protocolAddress,
            Percentages(
                lottoETHPercentage,
                nftCreatorETHPercentage,
                protocolETHPercentage
                )
            );
        ceremonyCount.increment();
    }

    function commit(address commiter, uint ceremonyId, bytes32 hashedValue) public payable {
        require(msg.value == ceremonies[ceremonyId].ticketPrice + ceremonies[ceremonyId].stakeAmount);
        randomnessCeremony.commit{value: ceremonies[ceremonyId].stakeAmount}(commiter, ceremonies[ceremonyId].randomnessCeremonyId, hashedValue);
        tickets[ceremonyId][ceremonies[ceremonyId].ticketCount] = commiter;
        ceremonies[ceremonyId].ticketCount += 1;
    }

    function reveal(uint ceremonyId, bytes32 hashedValue, bytes32 secretValue) public /** TODO Reentrancy */ {
        randomnessCeremony.reveal(ceremonies[ceremonyId].randomnessCeremonyId, hashedValue, secretValue);
    }

    function claimETH(uint ceremonyId) public {
        require(!ceremonies[ceremonyId].isETHClaimed, "Already claimed");
        ceremonies[ceremonyId].isETHClaimed = true;
        address winner = getWinner(ceremonyId, WinnerType.ETHWinner);
        uint lottoETHPercentage = ceremonies[ceremonyId].percentages.lottoETHPercentage;
        sendETH(
            payable(winner),
            (ceremonies[ceremonyId].ticketPrice * ceremonies[ceremonyId].ticketCount) * lottoETHPercentage / 10000
        );
    }

    function claimNFTCreatorETH(uint ceremonyId) public {
        require(!ceremonies[ceremonyId].isNFTCreatorETHClaimed, "Already claimed");
        ceremonies[ceremonyId].isNFTCreatorETHClaimed = true;
        address nftCreatorAddress = ceremonies[ceremonyId].nftCreatorAddress;
        uint nftCreatorETHPercentage = ceremonies[ceremonyId].percentages.nftCreatorETHPercentage;
        sendETH(
            payable(nftCreatorAddress),
            (ceremonies[ceremonyId].ticketPrice * ceremonies[ceremonyId].ticketCount) * nftCreatorETHPercentage / 10000
        );
    }

    function claimProtocolETH(uint ceremonyId) public {
        require(!ceremonies[ceremonyId].isProtocolETHClaimed, "Already claimed");
        ceremonies[ceremonyId].isProtocolETHClaimed = true;
        address protocolAddress = ceremonies[ceremonyId].protocolAddress;
        uint protocolETHPercentage = ceremonies[ceremonyId].percentages.protocolETHPercentage;
        sendETH(
            payable(protocolAddress),
            (ceremonies[ceremonyId].ticketPrice * ceremonies[ceremonyId].ticketCount) * protocolETHPercentage / 10000
        );
    }

    function claimNFT(uint ceremonyId) public {
        require(!ceremonies[ceremonyId].isNFTClaimed, "Already claimed");
        ceremonies[ceremonyId].isNFTClaimed = true;
        address winner = getWinner(ceremonyId, WinnerType.NFTWinner);
        IERC721(ceremonies[ceremonyId].nftContractAddress).transferFrom(address(this), winner, ceremonies[ceremonyId].nftID);
    }

    // Creator functions

    function claimSlashedETH(uint randomnessCeremonyId, bytes32 hashedValue, address to) public onlyOwner  {
        randomnessCeremony.claimSlashedETH(randomnessCeremonyId, hashedValue, to);
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