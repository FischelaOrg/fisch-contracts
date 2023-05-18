// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Fisch is ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint256;
    string public baseURI;

    error AssetIsFrozen(uint256 tokenId);

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
        string productLink
    );

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
        bool isFrozen;
        address ownerEmail;
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
        string memory _productLink,
        address _ownerEmail
    ) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        digitalAssets[tokenId] = DigitalAsset({
            owner: msg.sender,
            title: _title,
            description: _description,
            tokenId: tokenId,
            price: _intialPrice,
            assetURI: _assetURI,
            revenue: _revenue,
            expenses: _expenses,
            traffic: _traffic,
            productLink: _productLink,
            isFrozen: false,
            ownerEmail: _ownerEmail
        });

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

    function getNftItem(
        uint256 _tokenId
    ) public view returns (DigitalAsset memory) {
        return digitalAssets[_tokenId];
    }

    function freeze(uint256 _tokenId) public onlyOwner{
        digitalAssets[_tokenId].isFrozen = true;
    }

     function unfreeze(uint256 _tokenId) public onlyOwner{
        digitalAssets[_tokenId].isFrozen = false;
    }

    function safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) public nonReentrant {
        
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override {
        if (digitalAssets[_tokenId].isFrozen){
            revert AssetIsFrozen(_tokenId);
        }
        safeTransferFrom(_from, _to, _tokenId, data);
    }
}
