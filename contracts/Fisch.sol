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

    event AssetPromotedToCollateral(uint256 _tokenId);

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
        string ownerEmail;
        bool isCollateral;
    }

    struct DigiAssetInput {
        string title;
        string description;
        uint256 price;
        string assetURI;
        uint256 revenue;
        uint256 expenses;
        uint256 traffic;
        string productLink;
        string ownerEmail;
    }

    mapping(uint256 => DigitalAsset) public digitalAssets;

    constructor() ERC721("Fischela", "FIS") {
        _transferOwnership(msg.sender);
    }

    function mintNFT(DigiAssetInput memory digi) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        digitalAssets[tokenId] = DigitalAsset({
            owner: msg.sender,
            title: digi.title,
            description: digi.description,
            tokenId: tokenId,
            price: digi.price,
            assetURI: digi.assetURI,
            revenue: digi.revenue,
            expenses: digi.expenses,
            traffic: digi.traffic,
            productLink: digi.productLink,
            isFrozen: false,
            ownerEmail: digi.ownerEmail,
            isCollateral: false
        });

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, digi.assetURI);
        emit MintedNft(
            msg.sender,
            digi.title,
            digi.description,
            tokenId,
            digi.assetURI,
            digi.price,
            digi.revenue,
            digi.expenses,
            digi.traffic,
            digi.productLink
        );
        return tokenId;
    }

    function setBaseURI(
        string memory _baseURIStr //  onlyOwner
    ) public {
        baseURI = _baseURIStr;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPriceDigitalAsset(uint256 _price, uint256 tokenId) public {
        digitalAssets[tokenId].price = _price;
    }

    function getNftItem(
        uint256 _tokenId
    ) public view returns (DigitalAsset memory) {
        return digitalAssets[_tokenId];
    }

    function freeze(uint256 _tokenId) public {
        digitalAssets[_tokenId].isFrozen = true;
    }

    function unfreeze(uint256 _tokenId) public {
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
        if (digitalAssets[_tokenId].isFrozen) {
            revert AssetIsFrozen(_tokenId);
        }
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    function makeNftCollateral(uint256 _tokenId) public onlyOwner {
        DigitalAsset storage digi = digitalAssets[_tokenId];
        digi.isCollateral = true;

        emit AssetPromotedToCollateral(_tokenId);
    }

}
