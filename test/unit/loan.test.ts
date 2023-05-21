import { deployments, ethers } from "hardhat";
import {
  CowriesToken,
  Fisch,
  Fisch__factory,
  Loan,
  TimeLock,
  VillageSquare,
} from "../../typechain-types";
import { assert, expect } from "chai";

describe("Loan functionalities", async() => {
  let villageSquare: VillageSquare,
    timeLock: TimeLock,
    cowriesToken: CowriesToken,
    loan: Loan,
    fisch: Fisch;

  let [lender, borrower] = await ethers.getSigners();

  beforeEach(async () => {
    await deployments.fixture(["all"]);
    villageSquare = await ethers.getContract("VillageSquare");
    timeLock = await ethers.getContract("TimeLock");
    cowriesToken = await ethers.getContract("CowriesToken");
    fisch = await ethers.getContract("Fisch");
    loan = await ethers.getContract("Loan");
  });

  // it should create a loan
  it("should create a loan", async () => {
    const loanTx = await loan.createOrListLoan(5, 13, {value: ethers.utils.parseEther("100")});
    await loanTx.wait(3);

    const numberOfMonths = await loan.fetchLoanSingle(1);
    expect(numberOfMonths.loanDurationInMonthCount).equal(13);
  });

  // another user should borrow loan
  it(" should allow user borrow loan", async () => {
    const loanTx = await loan.createOrListLoan(5, 13);
    await loanTx.wait(3);

    const borrowTx = await loan
      .connect(borrower)
      .borrow(1, ethers.utils.parseUnits("5", 18), 1, borrower.address);

    await borrowTx.wait(2);

    let borrowValues = await loan.fetchBorrowSingle(1);
    expect(Number(ethers.utils.formatEther(borrowValues.currentBorrowAmount))).equal(5);

  });

  // loan should be approved by lender
  it(" should allow lender approve loan", async () => {
    const loanTx = await loan.createOrListLoan(5, 13);
    await loanTx.wait(3);

    const borrowTx = await loan
      .connect(borrower)
      .borrow(1, ethers.utils.parseUnits("5", 18), 1, borrower.address);

    await borrowTx.wait(2);

    const approveLoanTx = await loan.approveLoan(1);
    await approveLoanTx.wait(1);

    let borrowValues = await loan.fetchBorrowSingle(1);

    assert(borrowValues.isApproved);
  });

  // it should give the borrower ability to repay loan
  it(" should give the borrower ability to repay loan", async () => {});

  // it should liquidate collateral when loan duration passes
  it(" should liquidate collateral when loan duration passes", async () => {});

  // it should give the lender ability to cancel loan
  it(" should give the lender ability to cancel loan", async () => {});

  // it should give the lender ability to add funds
  it(" should give the lender ability to add funds", async () => {});

  // it should give the lender ability to lock and unlock loan
  it(" should give the lender ability to lock and unlock loan", async () => {});

  // it should give the lender ability to cancel loan making it inactive.
  it(" should give the lender ability to cancel loan making it inactive", async () => {});
});
