// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Fisch is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint256;
    string public baseURI;

    // EVENTS
    event MintedNft(
        address indexed owner,
        string ttile,
        string description,
        uint256 tokenId,
        string assetURI,
        uint256 price,
        uint256 revenue,
        uint256 expenses,
        uint256 traffic,
        string productLink);

    struct DigitalAsset {
        address owner;
        string title;
        string description;
        uint256 tokenId;
        uint256 price;
        string assetURI;
        uint256 revenue;
        uint256 expenses;
        uint256 traffic;
        string productLink;
    }
    mapping(uint256 => DigitalAsset) public digitalAssets;

    constructor() ERC721("Fischela", "FIS") {}

    function mintNFT(
        string memory _title,
        string memory _description,
        string memory _assetURI,
        uint256 _intialPrice,
        uint256 _revenue,
        uint256 _expenses,
        uint256 _traffic,
        string memory _productLink
    ) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _assetURI);
        emit MintedNft(
            msg.sender,
            _title, 
            _description, 
            tokenId, 
            _assetURI, 
            _intialPrice, 
            _revenue, 
            _expenses, 
            _traffic, 
            _productLink
        );
        return tokenId;
    }

    function setBaseURI(string memory _baseURI) public {
        baseURI = _baseURI;
    }

    function setPriceDigitalAsset(uint256 _price, uint256 tokenId) public {
        digitalAssets[tokenId].price = _price;
    }

    function safeTransfer(address from, address to, uint256 tokenId) public nonReentrant {
        _safeTransfer(from, to , tokenId, "");
    }
}