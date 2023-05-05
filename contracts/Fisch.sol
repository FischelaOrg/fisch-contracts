// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Fisch is ERC721, ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint256;
    string public baseURI;

    // EVENTS
    event mintedNFT(address indexed owner, string ttile, string description, uint256 tokenId, string assetURI);

    struct digitalAsset {
        address owner;
        string title;
        string description;
        uint256 tokenId;
        string assetURI;
    }

    constructor() ERC721("Fischela", "FIS") {}

    function mintNFT(
        string memory _title,
        string memory description,
        string memory assetURI
    ) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, assetURI);
        emit mintedNFT(msg.sender, _title, _description, tokenId, _assetURI);
        return tokenId;
    }

    function setBaseURI(string memory _baseURI) public {
        baseURI = _baseURI;
    }

    function safeTransfer(address from, address to, uint256 tokenId) public nonReentrant {
        _safeTransfer(from, to , tokenId, "");
    }
}