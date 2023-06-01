
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("Mock NFT", "MNFT") {
    }

    function mint(address to, uint nftId) public {
        _mint(to, nftId);
    }
}