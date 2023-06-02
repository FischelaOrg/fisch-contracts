// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Fisch.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract Marketplace is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _auctionIdCounter;

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
    event PlacedBid(
        uint256 bidAmount,
        address bidder,
        uint256 bidTime,
        uint256 auctionId,
        uint256 tokenId
    );
    event AuctionCancelled(uint256 auctionId, uint256 tokenId, address seller);
    event AuctionEnded(uint256 auctionId, address winner, uint256 settledPrice);
    event AuctionConfirmed(uint256 auctionId, address winner, uint256 settledPrice);
    event AmountSent(address indexed to, uint256 indexed amount);
    event AmountReceived(address sender, uint256 amount);

    uint256 public minimumBid = 1e18;

    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint256 reservePrice;
        bool started;
        bool resulted;
        address buyer;
        bool confirmed;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId = 0;

    struct HighestBidder {
        address bidder;
        uint256 bid;
        uint256 bidTime;
    }
    mapping(uint256 => HighestBidder) public highestBids;

    constructor(address _assetNft) {
        assetNftContract = Fisch(_assetNft);
    }

    function startAuction(
        uint256 tokenId,
        uint256 endTime,
        uint256 reservePrice
    ) external nonReentrant {
        uint256 auctionId = _auctionIdCounter.current();
        _auctionIdCounter.increment();
        

        auctions[auctionId] = Auction(
            tokenId,
            msg.sender,
            block.timestamp,
            endTime,
            reservePrice,
            true,
            false,
            address(0),
            false
        );
        console.log("END TIME: %s", auctions[auctionId].endTime);

        emit AuctionCreated(
            auctionId,
            tokenId,
            msg.sender,
            block.timestamp,
            endTime,
            reservePrice,
            true
        );
    }

    function cancelAuction(uint256 _auctionId) public {
        require(
            auctions[_auctionId].seller == msg.sender,
            "You are not the seller"
        );

        auctions[_auctionId].started = false;
        emit AuctionCancelled(
            _auctionId,
            auctions[_auctionId].tokenId,
            msg.sender
        );
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        emit AmountReceived(msg.sender, msg.value);
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function sendViaCall(address payable _to, uint256 _amount) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent /*bytes memory data*/, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Matic");
        emit AmountSent(_to, _amount);
    }

    function placeBid(uint256 _auctionId) public payable nonReentrant {
        console.log("block: %s, endTime: %s", block.timestamp, auctions[_auctionId].endTime);
        require(
            block.timestamp < auctions[_auctionId].endTime,
            "Auction has ended"
        );
        require(
            msg.sender != auctions[_auctionId].seller,
            "you should are not allowed to place a bid on your own auction."
        );
        require(msg.sender != address(0), "this is the address 0x00.. address");

        HighestBidder memory highestBidder = highestBids[_auctionId];
        uint256 minBid = highestBidder.bid.add(minimumBid);
        if (highestBidder.bid == 0) {
            minBid = highestBids[_auctionId].bid.add(minimumBid);
        }

        require(msg.value >= minBid, "Has not exceeded the best bid");

        delete highestBids[_auctionId];
        highestBids[_auctionId] = HighestBidder(
            msg.sender,
            msg.value,
            block.timestamp
        );

        emit PlacedBid(
            msg.value,
            msg.sender,
            block.timestamp,
            _auctionId,
            auctions[_auctionId].tokenId
        );
    }

     // chainlink automation will be in charge of calling result Auction
    function resultAuction(uint256 _auctionId) public {
        require(
            auctions[_auctionId].started,
            "The auction has not started yet"
        );

        require(
            block.timestamp > auctions[_auctionId].endTime,
            "The auction has not ended yet"
        );

        HighestBidder memory highestBidder = highestBids[_auctionId];
        // Function to transfer Matic from this contract to address from input
        assetNftContract.safeTransfer(
            auctions[_auctionId].seller,
            highestBidder.bidder,
            auctions[_auctionId].tokenId
        );
        auctions[_auctionId].started = false;
        auctions[_auctionId].resulted = true;
        auctions[_auctionId].buyer = highestBidder.bidder;

        emit AuctionEnded(_auctionId, highestBidder.bidder, highestBidder.bid);
    }

    function confirmAuction(uint256 _auctionId) public payable {
        
        require(
            block.timestamp > auctions[_auctionId].endTime,
            "The auction has not ended yet"
        );

        require(
            auctions[_auctionId].resulted,
            "Auction has not been resulted by the seller"
        );

        require(
            auctions[_auctionId].buyer == msg.sender,
            "Auction has not been resulted by the seller"
        );
        // require that auction has been resulted

        HighestBidder memory highestBidder = highestBids[_auctionId];
       

        // Function to transfer Matic from this contract to address from input
        sendViaCall(payable(auctions[_auctionId].seller), highestBidder.bid);
        
        auctions[_auctionId].confirmed = true;

        emit AuctionConfirmed(_auctionId, highestBidder.bidder, highestBidder.bid);
    }

   

    function fetchAuction(
        uint256 _auctionId
    ) public view returns (uint256 tokenId, address seller, uint256 startTime) {
        return (
            auctions[_auctionId].tokenId,
            auctions[_auctionId].seller,
            auctions[_auctionId].startTime
        );
    }
}
