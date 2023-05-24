import {
  TimeLock,
  Loan,
  VillageSquare,
  CowriesToken,
  Fisch,
} from "../typechain-types";
import { deployments, ethers, getNamedAccounts } from "hardhat";
import { assert, expect } from "chai";
import {
  FUNC,
  PROPOSAL_DESCRIPTION,
  NEW_STORE_VALUE,
  VOTING_DELAY,
  VOTING_PERIOD,
  MIN_DELAY,
} from "../utils/helper-constants";
import { moveBlocks } from "../utils/move-blocks";
import { moveTime } from "../utils/move-time";
import { Provider } from "@ethersproject/abstract-provider";
import { Signer } from "ethers";

describe("VillageSquare Flow", async () => {
  let villageSquare: VillageSquare;
  let cowriesToken: CowriesToken;
  let timeLock: TimeLock;
  let loan: Loan;
  let fisch: Fisch;
  const voteWay = 1; // for
  const reason = "I lika do da cha cha";
  let digi = {
    title: "Grand Theft Auto 6",
    description: "Grand theft auto Game rights",
    price: ethers.utils.parseEther("5"),
    assetURI: "www.grandTheftAuto",
    revenue: ethers.utils.parseEther("3000"),
    expenses: ethers.utils.parseEther("4000"),
    traffic: ethers.utils.parseEther("3000000"),
    productLink: "www.gta.com",
    ownerEmail: "gta@gmail.com",
  };

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
  });

  // loan part

  // it should create a loan
  it("should create a loan", async () => {
    const loanTx = await loan.createOrListLoan(5, 13, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();

    const loanValues = await loan.fetchLoanSingle(1);
    console.log(
      `Current loan Duration ${
        loanValues.loanDurationInMonthCount
      } and Innitial Amount ${ethers.utils.formatEther(
        loanValues.innitialLendAmount
      )}`
    );
    expect(loanValues.loanDurationInMonthCount).equal(13);
  });

  // another user should borrow loan
  it(" should allow user borrow loan", async () => {
    let { deployer, borrower, liquidator } = await getNamedAccounts();

    const loanTx = await loan.createOrListLoan(5, 13, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();

    const lendValues = await loan.fetchLoanSingle(1);

    const borrowTx = await loan
      .connect(await ethers.getSigner(borrower))
      .borrow(1, ethers.utils.parseUnits("5", 18), 0, borrower);

    await borrowTx.wait();

    let borrowValues = await loan.fetchBorrowSingle(1);

    console.log(
      `Current Borrowed Pending Loan: ${borrowValues.innitialBorrowAmount}`
    );
    expect(
      Number(ethers.utils.formatEther(borrowValues.innitialBorrowAmount))
    ).equal(5);
  });

  // loan should be approved by lender
  it(" should allow lender approve loan", async () => {
    let { deployer, borrower, liquidator } = await getNamedAccounts();

    const loanTx = await loan.createOrListLoan(
      ethers.utils.parseEther("5"),
      13,
      {
        value: ethers.utils.parseEther("100"),
      }
    );
    await loanTx.wait();

    let mintNFTTx = await fisch
      .connect(await ethers.getSigner(borrower))
      .mintNFT(digi);
    console.log("GOT HERE");

    await mintNFTTx.wait();
    const borrowTx = await loan
      .connect(await ethers.getSigner(borrower))
      .borrow(1, ethers.utils.parseUnits("5", 18), 0, borrower);

    await borrowTx.wait();

    const approveLoanTx = await loan
      .connect(await ethers.getSigner(deployer))
      .approveLoan(1);
    await approveLoanTx.wait();

    let borrowValues = await loan.fetchBorrowSingle(1);

    console.log(
      `Current Borrowed Approved Loan: ${borrowValues.innitialBorrowAmount}, amount to payback ${borrowValues.currentBorrowAmount}`
    );

    assert(borrowValues.isApproved);
  });

  // it should give the borrower ability to repay loan
  it(" should give the borrower ability to repay loan", async () => {
    let { _, borrower, __ } = await getNamedAccounts();

    const loanTx = await loan.createOrListLoan(5, 13, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();

    let mintNFTTx = await fisch
      .connect(await ethers.getSigner(borrower))
      .mintNFT(digi);
    console.log("GOT HERE");

    await mintNFTTx.wait();

    const borrowTx = await loan
      .connect(await ethers.getSigner(borrower))
      .borrow(1, ethers.utils.parseUnits("5", 18), 0, borrower);

    await borrowTx.wait();

    const approveLoanTx = await loan.approveLoan(1);
    await approveLoanTx.wait();

    let borrowValuesBefore = await loan.fetchBorrowSingle(1);

    await moveTime(60 * 60 * 24 * 3); // move three days

    const repayLoanTx = await loan
      .connect(await ethers.getSigner(borrower))
      .repayLoan(1, { value: ethers.utils.parseUnits("6", 18) });
    repayLoanTx.wait();

    let borrowValuesAfter = await loan.fetchBorrowSingle(1);
    console.log(
      `Amount in loan repaid ${borrowValuesAfter.amountAlreadyRemitted}, current Loan to be repaid ${borrowValuesAfter.currentBorrowAmount}`
    );
    assert(
      borrowValuesBefore.currentBorrowAmount >
        borrowValuesAfter.currentBorrowAmount
    );
  });

  // it should liquidate collateral when loan duration passes
  it(" should liquidate collateral when loan duration passes PRIVATE_SALE", async () => {
    let { deployer, borrower, liquidator } = await getNamedAccounts();

    const loanTx = await loan.createOrListLoan(5, 3, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();

    let mintNFTTx = await fisch
      .connect(await ethers.getSigner(borrower))
      .mintNFT(digi);
    console.log("GOT HERE");

    await mintNFTTx.wait();

    // set approval for all
    let approvalTx = await fisch
      .connect(await ethers.getSigner(borrower))
      .setApprovalForAll(loan.address, true);

    await approvalTx.wait();

    const borrowTx = await loan
      .connect(await ethers.getSigner(borrower))
      .borrow(1, ethers.utils.parseUnits("5", 18), 0, borrower);

    await borrowTx.wait();

    const approveLoanTx = await loan.approveLoan(1);
    await approveLoanTx.wait(1);

    await moveTime(60 * 60 * 24 * 7 * 4 * 5); // move three months

    const liquidateLoanTx = await loan
      .connect(await ethers.getSigner(liquidator))
      .liquidateCollateral(1, "PRIVATE_SALE", {
        value: ethers.utils.parseEther("5"),
      });
    liquidateLoanTx.wait();

    let borrowValues = await loan.fetchBorrowSingle(1);
    console.log(
      "Check if Loan has been repaid: ",
      borrowValues.isRepaid,
      " current borrow amount ",
      ethers.utils.formatEther(borrowValues.currentBorrowAmount)
    );
    expect(
      Number(ethers.utils.formatEther(borrowValues.currentBorrowAmount))
    ).equal(0);
  });

  // it should give the lender ability to cancel loan
  it(" should give the lender ability to cancel loan", async () => {
    const loanTx = await loan.createOrListLoan(5, 3, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();
    const cancelLoanTx = await loan.cancelLoan(1);
    cancelLoanTx.wait();
    const loanValues = await loan.fetchLoanSingle(1);
    assert(loanValues.isActive == false);
  });

  // it should give the lender ability to add funds
  it(" should give the lender ability to add funds", async () => {
    const loanTx = await loan.createOrListLoan(5, 3, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();

    let loanValuesBefore = await loan.fetchLoanSingle(1);
    console.log("Initial Lend Amount: ", loanValuesBefore.innitialLendAmount);
    const lockLoanTx = await loan.addfunds(1, {
      value: ethers.utils.parseUnits("5", 18),
    });
    lockLoanTx.wait();

    let loanValuesAfter = await loan.fetchLoanSingle(1);
    assert(
      Number(ethers.utils.formatUnits(loanValuesAfter.innitialLendAmount, 18)) >
        Number(
          ethers.utils.formatUnits(loanValuesBefore.innitialLendAmount, 18)
        )
    );
  });

  // it should give the lender ability to lock and unlock loan
  it(" should give the lender ability to lock loan", async () => {
    const loanTx = await loan.createOrListLoan(5, 3, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();
    const lockLoanTx = await loan.lockLoan(1);
    lockLoanTx.wait();
    const loanValues = await loan.fetchLoanSingle(1);
    console.log(loanValues.locked);
    assert(loanValues.locked == true);
  });

  // it should give the lender ability to cancel loan making it inactive.
  it(" should give the lender ability to unlock loan", async () => {
    const loanTx = await loan.createOrListLoan(5, 3, {
      value: ethers.utils.parseEther("100"),
    });
    await loanTx.wait();
    const lockLoanTx = await loan.lockLoan(1);
    lockLoanTx.wait();
    const unlockLoanTx = await loan.unlockLoan(1);
    unlockLoanTx.wait();
    const loanValues = await loan.fetchLoanSingle(1);
    assert(loanValues.locked == false);
  });
});
