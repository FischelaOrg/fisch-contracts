// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Fisch.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {

    Fisch assetNftContract;

    // EVENTS
    event AuctionCreated(
        uint256 auctionId,
        uint256 tokenId,
        address seller,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice,
        bool started
    );
    event AuctionBid();
    event AuctionCancelled(uint256 auctionId, uint256 tokenId, address seller);
    event AuctionEnded(uint256 auctionId, address winner, uint256 settledPrice);

    uint256 minimumBid = 1e18;

    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint256 reservePrice;
        bool started;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId = 0;

    struct HighestBidder {
        address bidder;
        uint256 bid;
    }
    mapping(uint256 => HighestBidder) public highestBids;


    constructor(address _assetNft) {
        assetNftContract = Fisch(_assetNft);
    }

    function startAuction(
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice
    ) external nonReentrant{
        uint256 auctionId = nextAuctionId++;

        auctions[auctionId] = Auction(
            tokenId,
            msg.sender,
            startTime,
            endTime,
            reservePrice,
            true
        );

        emit AuctionCreated(
            acountId,
            tokenId,
            msg.sender,
            startTime,
            endTime,
            reservePrice,
            true
        );
    }

    function cancelAuction(uint256 _auctionId) public {
        require(auctions[_auctionId].seller == msg.sender, "You are not the seller");

        auctions[_auctionId].started = false;
        emit AuctionCancelled(
            _auctionId,
            auctions[_auctionId].tokenId,
            msg.sender
        );
    }

    function placeBid(uint256 _auctionId) external payable {

        if (block.timestamp > auctions[_auctionId].endTime) {
            revert("Auction has ended");
        }

        HighestBidder memory highestBidder = highestBids[_auctionId];
        uint256 minBid = highestBidder.bid.add(minimumBid);
        if (highestBidder.bid == 0) {
            minBid = highestBids[_auctionId].add(minimumBid);
        }

        if (msg.value < minBid) {
            revert("Has not exceeded the best bid");
        }

        if (msg.sender != address(0)) {
            
        }

        emit AuctionBid();
    }

    function cancelBid() public {}

    function endAuction(uint256 _auctionId) public payable {
        require(auctions[_auctionId].started, "The auction has not started yet");
        require(block.timestamp < auctions[_auctionId].endTime, "The auction has not ended yet");

        HighestBidder memory highestBidder = highestBids[_auctionId];
        assetNftContract.safeTransfer(msg.sender, highestBidder.bidder, auctions[_auctionId].tokenId);
        auctions[_auctionId].started = false;

        emit AuctionEnded(_auctionId, highestBidder.bidder, highestBidder.bid);
    }    

}