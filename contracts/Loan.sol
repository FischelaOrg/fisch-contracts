// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Loan is Ownable {
    // default loan duration
    uint256 private _defaultLoanDuration = 12 weeks;
    uint256 public defaultInterestRate = 5;
    using Counters for Counters.Counter;
    Counters.Counter private _borrowersIds;
    Counters.Counter private _lendersIds;

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

    // create a struct for borowers
    struct Borrower {
        uint256 borrowerId;
        address borrower;
        uint256 borrowAmount;
        uint256 repaymentCapacity;
        uint256 deadline;
        uint256 interest;
        uint256 lenderId;
        uint256 nftCollateralId;
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
    ) public view returns (uint256 si) {
        return si = (pricipalAmount * interestRate * duration) / 100;
    }

    // first create a function to borrow all
    // Borrow

    function borrow(uint256 _loanId, uint256 _amount, uint256 _nftCollateralId) public {
        // create Loan
        _borrowersIds.increment();

        uint256 currentCounter = _borrowersIds.current();
        _borrowers[currentCounter] = Borrower({
            borrowerId: 0,
            borrower: 0,
            borrowAmount: 0,
            repaymentCapacity: 0,
            deadline: 0,
            interest: 0,
            lenderId: 0,
            nftCollateralId: 0
        });

        emit LoanBorrowed(_lenders[currentCounter].loanId);
    }

    // repayLoan ---- monthly repayment of loans
    function repayLoan() public {}

    // liquidateCollateral
    function liquidateCollateral() public {}

    // approveLoan
    function approveLoan() public {}

    // cancelLoan
    function cancelLoan() public {}
}
