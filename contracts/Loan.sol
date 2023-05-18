// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./Fisch.sol";

contract Loan is Ownable {
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
        uint256 innitialBorrowAmount;
        uint256 currentBorrowAmount;
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
    // create a struct for borowers
    struct Borrower {
        uint256 borrowerId;
        address borrower;
        uint256 borrowAmount;
        uint256 repayAmount;
        uint256 amountAlreadyRemitted;
        uint256 deadline;
        uint256 interest;
        uint256 lenderId;
        uint256 nftCollateralId;
        address receiverAddress;
        bool isApproved;
    }

    // create a list of lenders

    mapping(uint256 => Lender) private _lenders;

    // create a list of borrrowers

    mapping(uint256 => Borrower) private _borrowers;

    // createLoan
    function createOrListLoan(
        uint256 _innitialBorrowAmount,
        uint256 _interestRate,
        uint256 _loanOutDuration
    ) public payable {
        // create Loan
        _lendersIds.increment();

        uint256 currentCounter = _lendersIds.current();
        _lenders[currentCounter] = Lender({
            loanId: currentCounter,
            currentBorrowAmount: _innitialBorrowAmount,
            amountRepaid: 0,
            locked: true,
            isActive: false,
            lender: msg.sender,
            innitialBorrowAmount: _innitialBorrowAmount,
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
        uint256 _nftCollateralId,
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
            borrowAmount: _borrowAmount,
            repayAmount: 0,
            amountAlreadyRemitted: 0,
            deadline: 0,
            interest: 0,
            lenderId: _lenderId,
            nftCollateralId: _nftCollateralId,
            receiverAddress: msg.sender,
            isApproved: false
        });

        emit LoanBorrowed(_lenders[currentCounter].loanId);
    }

     // approveLoan
    function approveLoan(uint256 _borrowerId) public {
        Borrower storage borrower = _borrowers[_borrowerId];
        if (borrower.receiverAddress != msg.sender){
            revert SenderNotReceiver(borrower.receiverAddress, msg.sender);
        }
    }

    // repayLoan ---- monthly repayment of loans
    function repayLoan() public {}

    // liquidateCollateral
    function liquidateCollateral() public {}

    // cancelLoan
    function cancelLoan() public {}
}
