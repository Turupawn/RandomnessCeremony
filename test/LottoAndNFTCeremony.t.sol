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

    function setUp() public {
        randomnessCeremony = new RandomnessCeremony();
        mockNFT = new MockNFT();
        lottoAndNFTCeremony = new LottoAndNFTCeremony(address(randomnessCeremony));
    }

    function testLottoAndNFTCeremony() public {
        address user1 = makeAddr("alice");
        address user2 = makeAddr("bob");
        address user3 = makeAddr("ana");

        // The ceremony master kickstarts the randomness generation
        uint commitmentDeadline = block.timestamp + 1 days;
        uint revealDeadline = block.timestamp + 2 days;
        uint ticketPrice = 0.1 ether;
        uint stakeAmount = 0.2 ether;
        mockNFT.mint(address(this), 0);
        mockNFT.approve(address(lottoAndNFTCeremony),0);
        lottoAndNFTCeremony.createCeremony(
            commitmentDeadline,
            revealDeadline,
            ticketPrice,
            stakeAmount,
            0,
            address(mockNFT),
            address(user1),
            address(user2),
            2500,
            500);
        
        // Now we hash 3 secrets
        bytes32 secret1 = "secret1";
        bytes32 secret2 = "secret2";
        bytes32 secret3 = "secret3";
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

        // The reveal window closes and the winner is rewarded
        vm.warp(block.timestamp + 1 days + 1);
        lottoAndNFTCeremony.claimETH(0);
        lottoAndNFTCeremony.claimNFT(0);
    }
}
