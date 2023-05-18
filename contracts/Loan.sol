// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Fisch.sol";

contract Loan is Ownable, ReentrancyGuard {
    // default loan duration
    uint256 private _defaultLoanDuration = 12 weeks;
    uint256 public defaultInterestRate = 5;
    using Counters for Counters.Counter;
    Counters.Counter private _borrowersIds;
    Counters.Counter private _lendersIds;
    Fisch public nftCollateral;

    constructor(Fisch _nftCollateralAddress) {
        nftCollateral = _nftCollateralAddress;
    }

    // create a struct for Lenders
    struct Lender {
        uint256 loanId;
        uint256 innitialLendAmount;
        uint256 currentLendAmount;
        uint256 amountRepaid;
        uint256 borrowerId;
        uint256 interestRate; // using compound interest SI = PRT/100 to calculate interest rate
        uint256 loanOutDuration;
        bool locked;
        bool isActive;
        address lender;
    }

    event LoanCreated(uint256 loanId);

    event LoanBorrowed(uint256 borrowId);

    // errors

    error SenderNotReceiver(address sender, address receiver);
    error LoanNotActive();
    error TransferFailed();

    // modifiers
    modifier onlyLender(address _lender){
        require(msg.sender == _lender, "Sender not Lender");
        _;
    }
    // create a struct for borowers
    struct Borrower {
        uint256 borrowerId;
        address borrower;
        uint256 innitialBorrowAmount;
        uint256 currentBorrowAmount;
        uint256 amountAlreadyRemitted;
        uint256 deadline;
        uint256 interest;
        uint256 lenderId;
        uint256 nftCollateralTokenId;
        address receiverAddress;
        bool isApproved;
        bool isRepayed;
    }

    // create a list of lenders

    mapping(uint256 => Lender) private _lenders;

    // create a list of borrrowers

    mapping(uint256 => Borrower) private _borrowers;

    // createLoan
    function createOrListLoan(
        uint256 _innitialLendAmount,
        uint256 _interestRate,
        uint256 _loanOutDuration
    ) public payable {
        // create Loan
        _lendersIds.increment();

        uint256 currentCounter = _lendersIds.current();
        _lenders[currentCounter] = Lender({
            loanId: currentCounter,
            currentLendAmount: _innitialLendAmount,
            amountRepaid: 0,
            locked: false,
            isActive: true,
            lender: msg.sender,
            innitialLendAmount: _innitialLendAmount,
            interestRate: _interestRate,
            loanOutDuration: _loanOutDuration,
            borrowerId: 0
        });

        emit LoanCreated(_lenders[currentCounter].loanId);
    }

    // calculate simple interest
    function calculateLoanInterest(
        uint256 pricipalAmount,
        uint256 interestRate,
        uint256 duration
    ) public pure returns (uint256 si) {
        return si = (pricipalAmount * interestRate * duration) / 100;
    }

    // first create a function to borrow all
    // Borrow

    function borrow(
        uint256 _lenderId,
        uint256 _borrowAmount,
        uint256 _nftCollateralTokenId,
        address receiverAddress
    ) public {
        // check if receiver address equals msg.sender
        if (receiverAddress != msg.sender) {
            revert SenderNotReceiver(msg.sender, receiverAddress);
        }

        if (!_lenders[_lenderId].isActive) {
            revert LoanNotActive();
        }
        // create Loan
        _borrowersIds.increment();
        uint256 currentCounter = _borrowersIds.current();
        _borrowers[currentCounter] = Borrower({
            borrowerId: currentCounter,
            borrower: msg.sender,
            currentBorrowAmount: 0,
            innitialBorrowAmount: _borrowAmount,
            amountAlreadyRemitted: 0,
            deadline: 0,
            interest: 0,
            lenderId: _lenderId,
            nftCollateralTokenId: _nftCollateralTokenId,
            receiverAddress: msg.sender,
            isApproved: false,
            isRepayed: false
        });

        emit LoanBorrowed(_lenders[currentCounter].loanId);
    }

    // approveLoan
    /*
        - approve loan verifies receiver
        - freezes nft collateral
        - transfers loan to borrower
     */
    function approveLoan(uint256 _borrowerId) public onlyOwner nonReentrant {
        Borrower storage borrower = _borrowers[_borrowerId];
        if (borrower.receiverAddress != msg.sender) {
            revert SenderNotReceiver(borrower.receiverAddress, msg.sender);
        }

        // freeze NFT
        nftCollateral.freeze(borrower.nftCollateralTokenId);

        Lender storage lender = _lenders[borrower.lenderId];

        // deduct loan amount from lender
        lender.currentLendAmount -= borrower.innitialBorrowAmount;

        // set loan deadline
        borrower.deadline = block.timestamp + lender.loanOutDuration;

        // add loan amount to borrower
        borrower.currentBorrowAmount += borrower.innitialBorrowAmount;

        // transfer loan to msgSender
        (bool success, ) = msg.sender.call{
            value: borrower.innitialBorrowAmount
        }("");

        if (!success) {
            revert TransferFailed();
        }
    }

    // repayLoan ---- monthly repayment of loans
    /*
     * Repay loan
     * checks if current amount repays all the loan
     * transfers amount to lender
     * exonerates borrower
     */
    function repayLoan(uint256 _borrowerId) public payable nonReentrant {
        // check if current msg.value repays loan
        Borrower storage borrower = _borrowers[_borrowerId];
        Lender storage lender = _lenders[borrower.lenderId];

        if (borrower.amountAlreadyRemitted >= borrower.innitialBorrowAmount) {
            borrower.isRepayed = true;
        }

        // transfer amount to lender
        lender.currentLendAmount -= msg.value;
        lender.amountRepaid += msg.value;

        // exonerate borrower
        borrower.amountAlreadyRemitted += msg.value;
        borrower.currentBorrowAmount -= msg.value;

        nftCollateral.unfreeze(borrower.nftCollateralTokenId);
    }

    // liquidateCollateral
    /*
        * Liquidate collateral 
    */
    function liquidateCollateral(uint256 _borrowerId) public {}

    // cancelLoan
    function cancelLoan(uint256 _lenderId) public onlyLender(_lenders[_lenderId].lender){
        _lenders[_lenderId].isActive = false;
    }

    receive() external payable {}

    fallback() external payable {}
}
