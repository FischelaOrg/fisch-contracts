// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Loan is Ownable {
    // default loan duration
    uint256 private _defaultLoanDuration = 12 weeks;
    uint256 public defaultInterestRate = 5;

    // create a struct for Lenders
    struct Lender{
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

    event LoanCreated(

    );

    event LoanBorrowed(

    );

    // create a struct for borowers
    struct Borrower{
        uint256 borrowerId;
        address borrower;
        uint256 borrowAmount;
        uint256 repaymentCapacity;
        uint256 deadline;
        uint256 interest;
        uint256 lenderId;
        uint256 nftCollateralId

    }

    // create a list of lenders

    Lender[] private _lenders;

    // create a list of borrrowers

    Borrower[] private _borrowers;

    // createLoan
    function createLoan(uint256 innitialBorrowAmount, uint256 interestRate, uint256 loanOutDuration) public payable{
        // create Loan
    }

    // calculate simple interest
    function calculateLoanInterest() public {

    }

    // first create a function to borrow all
    // Borrow

    function borrow() public {

    }

    // repayLoan ---- monthly repayment of loans
    function repayLoan() public {

    }

    // liquidateCollateral
    function liquidateCollateral() public {

    }

    // approveLoan
    function approveLoan() public {

    }

    // cancelLoan
    function cancelLoan() public {

    }
}
