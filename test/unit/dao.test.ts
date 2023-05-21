import {
  TimeLock,
  Loan,
  VillageSquare,
  CowriesToken,
  Fisch,
} from "../../typechain-types";
import { deployments, ethers } from "hardhat";
import { assert, expect } from "chai";
import {
  FUNC,
  PROPOSAL_DESCRIPTION,
  NEW_STORE_VALUE,
  VOTING_DELAY,
  VOTING_PERIOD,
  MIN_DELAY,
} from "../../utils/helper-constants";
import { moveBlocks } from "../../utils/move-blocks";
import { moveTime } from "../../utils/move-time";

describe("VillageSquare Flow", async () => {
  let villageSquare: VillageSquare;
  let cowriesToken: CowriesToken;
  let timeLock: TimeLock;
  let loan: Loan;
  let fisch: Fisch;
  const voteWay = 1; // for
  const reason = "I lika do da cha cha";
  beforeEach(async () => {
    await deployments.fixture(["all"]);
    villageSquare = await ethers.getContract("VillageSquare");
    timeLock = await ethers.getContract("TimeLock");
    cowriesToken = await ethers.getContract("CowriesToken");
    fisch = await ethers.getContract("Fisch");
    loan = await ethers.getContract("Loan");
  });

  it("can only be changed through governance", async () => {
    await expect(fisch.makeNftCollateral(1)).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });

  it("proposes, votes, waits, queues, and then executes", async () => {
    // propose
    const encodedFunctionCall = fisch.interface.encodeFunctionData(FUNC, [
      NEW_STORE_VALUE,
    ]);
    const proposeTx = await villageSquare.propose(
      [loan.address],
      [0],
      [encodedFunctionCall],
      PROPOSAL_DESCRIPTION
    );

    const proposeReceipt = await proposeTx.wait(1);
    const proposalId = proposeReceipt.events![0].args!.proposalId;
    let proposalState = await villageSquare.state(proposalId);
    console.log(`Current Proposal State: ${proposalState}`);

    await moveBlocks(VOTING_DELAY + 1);
    // vote
    const voteTx = await villageSquare.castVoteWithReason(
      proposalId,
      voteWay,
      reason
    );
    await voteTx.wait(1);
    proposalState = await villageSquare.state(proposalId);
    assert.equal(proposalState.toString(), "1");
    console.log(`Current Proposal State: ${proposalState}`);
    await moveBlocks(VOTING_PERIOD + 1);

    // queue & execute
    // const descriptionHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(PROPOSAL_DESCRIPTION))
    const descriptionHash = ethers.utils.id(PROPOSAL_DESCRIPTION);
    const queueTx = await villageSquare.queue(
      [loan.address],
      [0],
      [encodedFunctionCall],
      descriptionHash
    );
    await queueTx.wait(1);
    await moveTime(MIN_DELAY + 1);
    await moveBlocks(1);

    proposalState = await villageSquare.state(proposalId);
    console.log(`Current Proposal State: ${proposalState}`);

    console.log("Executing...");
    console.log;
    const exTx = await villageSquare.execute(
      [loan.address],
      [0],
      [encodedFunctionCall],
      descriptionHash
    );
    await exTx.wait(1);
    console.log((await fisch.getNftItem(1)).toString());
  });
});
