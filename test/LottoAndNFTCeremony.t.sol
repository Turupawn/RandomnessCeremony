// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RandomnessCeremony.sol";
import "../src/LottoAndNFTCeremony.sol";
import "../src/MockNFT.sol";

contract LottoAndNFTCeremonyTest is Test {
    LottoAndNFTCeremony public lottoAndNFTCeremony;
    RandomnessCeremony public randomnessCeremony;
    MockNFT public mockNFT;
    address public nftCreator;
    address public protocol;

    address public user1 = makeAddr("alice");
    address public user2 = makeAddr("bob");
    address public user3 = makeAddr("ana");

    bytes32 public secret1 = "secret1";
    bytes32 public secret2 = "secret2";
    bytes32 public secret3 = "secret3";

    function setUp() public {
        randomnessCeremony = new RandomnessCeremony();
        lottoAndNFTCeremony = new LottoAndNFTCeremony(address(randomnessCeremony));
        mockNFT = new MockNFT();
        nftCreator = makeAddr("nft-creator");
        protocol = makeAddr("protocol");
        // Let's mint the raffled NFT and approve the lotto contract
        mockNFT.mint(address(this),0);
        mockNFT.approve(address(lottoAndNFTCeremony), 0);
    }

    function testLottoAndNFTCeremony() public {
        // The ceremony master kickstarts the randomness generation
        uint commitmentDeadline = block.timestamp + 1 days;
        uint revealDeadline = block.timestamp + 2 days;
        uint ticketPrice = 0.1 ether;
        uint stakeAmount = 0.2 ether;
        uint nftID = 0;
        uint nftCreatorETHPercentage = 2400;
        uint protocolETHPercentage = 100;
        lottoAndNFTCeremony.createCeremony(
            commitmentDeadline,
            revealDeadline,
            ticketPrice,
            stakeAmount,
            nftID,
            address(mockNFT),
            nftCreator,
            protocol,
            nftCreatorETHPercentage,
            protocolETHPercentage
            );
        
        // Now we hash 3 secrets
        bytes32 hashedValue1 = keccak256(abi.encodePacked(secret1));
        bytes32 hashedValue2 = keccak256(abi.encodePacked(secret2));
        bytes32 hashedValue3 = keccak256(abi.encodePacked(secret3));

        // And we commit to them using 3 different users 
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user1, 0, hashedValue1);
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user2, 0, hashedValue2);
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user3, 0, hashedValue3);        

        // The reveal window opens, so we reveal the 3 secrets
        vm.warp(block.timestamp + 1 days + 1);
        lottoAndNFTCeremony.reveal(0, hashedValue1, secret1);
        lottoAndNFTCeremony.reveal(0, hashedValue2, secret2);
        lottoAndNFTCeremony.reveal(0, hashedValue3, secret3);

        // The reveal window closes
        vm.warp(block.timestamp + 1 days + 1);

        // The owner shouldn't be able to force claim
        vm.expectRevert();
        lottoAndNFTCeremony.forceClaim(0, protocol);
        
        // Nor slash
        vm.expectRevert();
        lottoAndNFTCeremony.claimSlashedETH(0, hashedValue1, protocol);
        vm.expectRevert();
        lottoAndNFTCeremony.claimSlashedETH(0, hashedValue2, protocol);
        vm.expectRevert();
        lottoAndNFTCeremony.claimSlashedETH(0, hashedValue3, protocol);

        // The claim should happen as normal
        lottoAndNFTCeremony.claimETH(0);
        lottoAndNFTCeremony.claimNFT(0);
        lottoAndNFTCeremony.claimNFTCreatorETH(0);
        lottoAndNFTCeremony.claimProtocolETH(0);

    }

    function testSlashing() public {
        // The ceremony master kickstarts the randomness generation
        uint commitmentDeadline = block.timestamp + 1 days;
        uint revealDeadline = block.timestamp + 2 days;
        uint ticketPrice = 0.1 ether;
        uint stakeAmount = 0.2 ether;
        uint nftID = 0;
        uint nftCreatorETHPercentage = 2400;
        uint protocolETHPercentage = 100;
        lottoAndNFTCeremony.createCeremony(
            commitmentDeadline,
            revealDeadline,
            ticketPrice,
            stakeAmount,
            nftID,
            address(mockNFT),
            nftCreator,
            protocol,
            nftCreatorETHPercentage,
            protocolETHPercentage
            );
        
        // Now we hash 3 secrets
        bytes32 hashedValue1 = keccak256(abi.encodePacked(secret1));
        bytes32 hashedValue2 = keccak256(abi.encodePacked(secret2));
        bytes32 hashedValue3 = keccak256(abi.encodePacked(secret3));

        // And we commit to them using 3 different users 
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user1, 0, hashedValue1);
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user2, 0, hashedValue2);
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user3, 0, hashedValue3);        

        // The reveal window opens, we reveal 1 secrets and leave one unrevealed
        vm.warp(block.timestamp + 1 days + 1);
        lottoAndNFTCeremony.reveal(0, hashedValue1, secret1);
        lottoAndNFTCeremony.reveal(0, hashedValue2, secret2);
        // We won't reveal a secret so we can slash it
        //lottoAndNFTCeremony.reveal(0, hashedValue3, secret3);

        // The reveal window closes
        vm.warp(block.timestamp + 1 days + 1);

        // The non relvealer get's slashed
        lottoAndNFTCeremony.claimSlashedETH(0, hashedValue3, protocol);

        // The rest can't be slashed
        vm.expectRevert();
        lottoAndNFTCeremony.claimSlashedETH(0, hashedValue1, protocol);
        vm.expectRevert();
        lottoAndNFTCeremony.claimSlashedETH(0, hashedValue2, protocol);

        // Claims should happen as normal
        lottoAndNFTCeremony.claimETH(0);
        lottoAndNFTCeremony.claimNFT(0);
        lottoAndNFTCeremony.claimNFTCreatorETH(0);
        lottoAndNFTCeremony.claimProtocolETH(0);
    }

    function testForceClaim() public {
        // The ceremony master kickstarts the randomness generation
        uint commitmentDeadline = block.timestamp + 1 days;
        uint revealDeadline = block.timestamp + 2 days;
        uint ticketPrice = 0.1 ether;
        uint stakeAmount = 0.2 ether;
        uint nftID = 0;
        uint nftCreatorETHPercentage = 2400;
        uint protocolETHPercentage = 100;
        lottoAndNFTCeremony.createCeremony(
            commitmentDeadline,
            revealDeadline,
            ticketPrice,
            stakeAmount,
            nftID,
            address(mockNFT),
            nftCreator,
            protocol,
            nftCreatorETHPercentage,
            protocolETHPercentage
            );
        
        // Now we hash only 2 secrets
        bytes32 hashedValue1 = keccak256(abi.encodePacked(secret1));
        bytes32 hashedValue2 = keccak256(abi.encodePacked(secret2));

        // And we commit to them using only 2 different users 
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user1, 0, hashedValue1);
        lottoAndNFTCeremony.commit{value: 0.3 ether}(user2, 0, hashedValue2);

        // The reveal window opens we only reveal 2 secrets
        vm.warp(block.timestamp + 1 days + 1);
        lottoAndNFTCeremony.reveal(0, hashedValue1, secret1);
        lottoAndNFTCeremony.reveal(0, hashedValue2, secret2);

        // The reveal window closes
        vm.warp(block.timestamp + 1 days + 1);

        // ETH winner and NFT can't claim due to not enough tickets sold (Feistel requirement)
        vm.expectRevert();
        lottoAndNFTCeremony.claimETH(0);
        vm.expectRevert();
        lottoAndNFTCeremony.claimNFT(0);
        // The NFT creator and protocol should claim as normal
        lottoAndNFTCeremony.claimNFTCreatorETH(0);
        lottoAndNFTCeremony.claimProtocolETH(0);

        // ETH and NFT should only be claimed by the owner due to not enough tickets sold
        lottoAndNFTCeremony.forceClaim(0, protocol);
    }
}
