import {
    Fisch,
    Marketplace,
  } from "../../typechain-types";
import { deployments, ethers } from "hardhat";
import { assert, expect } from "chai";
import {
    TOKENID,
    MIN_PRICE
} from "../../utils/helper-constants";
import {getLastTimestamp, day } from "../../utils/test-helper";

describe("Marketplace Flow", async () => {
    let marketplace: Marketplace;
    let fisch: Fisch;
    const curTime = await getLastTimestamp();
    const startTime = curTime + day;
    const endTime = curTime + 2 * day    
    let user1: any;
    let user2: any;
    beforeEach(async () => {
        await deployments.fixture(["all"]);
        marketplace = await ethers.getContract("Marketplace");
        fisch = await ethers.getContract("Fisch");
    });

    it("should allow seller to create default Auction", async function () {
        await marketplace.connect(user1).startAuction(
            TOKENID,
            startTime,
            endTime,
            MIN_PRICE
        );
        let result = await marketplace.auctions(TOKENID);
        expect(result.seller).to.equal(user1.address);
    });

    it("should allow bidder to place a bid", async function () {
        await marketplace.connect(user2).placeBid(TOKENID);
    });

    it("result auction", async function () {});

    it("cancel auction", async function () {});
});