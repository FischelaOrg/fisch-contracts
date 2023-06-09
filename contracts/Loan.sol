// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Fisch.sol";

contract Loan is Ownable, ReentrancyGuard {
    // default loan duration
    using SafeMath for uint256;
    uint256 private _defaultLoanDuration = 12;
    uint256 public defaultInterestRate = 5;
    bytes32 public constant PUBLIC_SALE =
        keccak256(abi.encodePacked("PUBLIC_SALE"));
    bytes32 public constant PRIVATE_SALE =
        keccak256(abi.encodePacked("PRIVATE_SALE"));

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
        uint256 currentAvailableLendAmount;
        uint256 amountRepaid;
        uint256 borrowerId;
        uint256 interestRate; // using compound interest SI = PRT/100 to calculate interest rate
        uint256 loanOutDuration;
        bool locked;
        bool isActive;
        address lender;
        uint256 loanDurationInMonthCount;
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
        bool isRepaid;
    }

    // events

    event LoanCreated(
        uint256 loanId,
        uint256 innitialLendAmount,
        uint256 currentAvailableLendAmount,
        uint256 amountRepaid,
        uint256 borrowerId,
        uint256 interestRate, // using compound interest SI = PRT/100 to calculate interest rate
        uint256 loanOutDuration,
        bool locked,
        bool isActive,
        address lender,
        uint256 loanDurationInMonthCount
    );

    event LoanBorrowed(
        uint256 borrowId,
        uint256 amount,
        uint256 lenderId,
        address lender,
        address borrower,
        uint256 innitialBorrowAmount,
        uint256 currentBorrowAmount,
        uint256 amountAlreadyRemitted,
        uint256 deadline,
        uint256 interest,
        uint256 nftCollateralTokenId,
        address receiverAddress,
        bool isApproved,
        bool isRepaid
    );

    event LoanApproved(
        uint256 lenderId,
        uint256 borrowerId,
        address lender,
        address borrower,
        uint256 amount,
        uint256 deadline,
        uint256 currentBorrowAmount,
        bool isApproved
    );
    event LoanRepayed(
        uint256 lenderId,
        uint256 borrowerId,
        address lender,
        address borrower,
        uint256 amount,
        uint256 currentAvailableLendAmount,
        uint256 amountRepaid,
        uint256 amountAlreadyRemitted,
        uint256 currentBorrowAmount,
        bool isRepaid
    );
    event CollateralLiquidated(
        uint256 lenderId,
        uint256 borrowerId,
        address lender,
        address borrower,
        uint256 amount,
        address liquidator,
        uint256 currentAvailableLendAmount,
        uint256 amountRepaid,
        uint256 currentBorrowAmount,
        bool isRepaid,
        uint256 amountAlreadyRemitted
    );

    event LoanCancelled(
        uint256 lenderId,
        address lender,
        uint256 amount,
        bool isActive
    );

    event FundsAdded(
        uint256 currentAvailableLendAmount,
        uint256 innitialLendAmount,
        address lender,
        uint256 loanId
    );
    event LoanUnLocked(uint256 loanId, bool locked);
    event LoanLocked(uint256 loanId, bool locked);

    // errors

    error SenderNotReceiver(address sender, address receiver);
    error LoanNotActive();
    error TransferFailed();
    error LoanIsLocked();

    // modifiers
    modifier onlyLender(address _lender) {
        require(msg.sender == _lender, "Sender not Lender");
        _;
    }

    modifier onlyWhenOverdue(uint256 _borrowerId) {
        Borrower memory borrower = _borrowers[_borrowerId];
        require(block.timestamp > borrower.deadline, "Loan is not overdue");
        _;
    }

    // create a list of lenders

    mapping(uint256 => Lender) private _lenders;

    // create a list of borrrowers

    mapping(uint256 => Borrower) private _borrowers;

    // createLoan
    function createOrListLoan(
        uint256 _interestRate,
        uint256 _loanDurationMonthCount
    ) public payable {
        // create Loan
        _lendersIds.increment();

        uint256 currentCounter = _lendersIds.current();
        _lenders[currentCounter] = Lender({
            loanId: currentCounter,
            currentAvailableLendAmount: msg.value,
            amountRepaid: 0,
            locked: false,
            isActive: true,
            lender: msg.sender,
            innitialLendAmount: msg.value,
            interestRate: _interestRate,
            loanOutDuration: convertMonthsToSeconds(
                _loanDurationMonthCount != 0
                    ? _loanDurationMonthCount
                    : _defaultLoanDuration
            ),
            borrowerId: 0,
            loanDurationInMonthCount: _loanDurationMonthCount != 0
                ? _loanDurationMonthCount
                : _defaultLoanDuration
        });

        emit LoanCreated(
            _lenders[currentCounter].loanId,
            _lenders[currentCounter].innitialLendAmount,
            _lenders[currentCounter].currentAvailableLendAmount,
            _lenders[currentCounter].amountRepaid,
            _lenders[currentCounter].borrowerId,
            _lenders[currentCounter].interestRate,
            _lenders[currentCounter].loanOutDuration,
            _lenders[currentCounter].locked,
            _lenders[currentCounter].isActive,
            _lenders[currentCounter].lender,
            _lenders[currentCounter].loanDurationInMonthCount
        );
    }

    // calculate simple interest
    function calculateLoanInterest(
        uint256 pricipalAmount,
        uint256 interestRate,
        uint256 durationMonths
    ) public pure returns (uint256 si) {
        return
            si = (pricipalAmount * interestRate * durationMonths) / (100 * 12);
    }

    // convert months to weeks
    function convertMonthsToWeeks(
        uint256 _noOfMonth
    ) public pure returns (uint256 noOfweeks) {
        return noOfweeks = 4 * _noOfMonth;
    }

    function convertWeeksToSeconds(
        uint256 noOfWeeks
    ) public pure returns (uint256 secondsByWeeks) {
        return secondsByWeeks = noOfWeeks * 1 weeks;
    }

    function convertMonthsToSeconds(
        uint256 _noOfMonth
    ) public pure returns (uint256 secondsByMonth) {
        uint256 weekds = convertMonthsToWeeks(_noOfMonth);
        secondsByMonth = convertWeeksToSeconds(weekds);
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
        Lender memory lender = _lenders[_lenderId];

        if (receiverAddress != msg.sender) {
            revert SenderNotReceiver(msg.sender, receiverAddress);
        }

        if (!lender.isActive) {
            revert LoanNotActive();
        }

        if (lender.locked) {
            revert LoanIsLocked();
        }

        // calculate amount to be repayed

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
            isRepaid: false
        });

        Borrower memory borrower = _borrowers[currentCounter];

        emit LoanBorrowed(
            lender.loanId, //loanId
            borrower.innitialBorrowAmount, //
            _lenderId,
            lender.lender,
            borrower.borrower,
            borrower.currentBorrowAmount,
            borrower.innitialBorrowAmount,
            borrower.amountAlreadyRemitted,
            borrower.deadline,
            borrower.interest,
            borrower.nftCollateralTokenId,
            borrower.receiverAddress,
            borrower.isApproved,
            borrower.isRepaid
        );
    }

    // approveLoan
    /*
        - approve loan verifies receiver
        - freezes nft collateral
        - transfers loan to borrower
     */
    function approveLoan(uint256 _borrowerId) public nonReentrant {
        Borrower storage borrower = _borrowers[_borrowerId];
        Lender storage lender = _lenders[borrower.lenderId];

        if (
            nftCollateral.ownerOf(borrower.nftCollateralTokenId) !=
            borrower.borrower
        ) {
            revert("Borrower not NFT owner");
        }

        if (
            nftCollateral.getNftItem(borrower.nftCollateralTokenId).isCollateral
        ) {
            revert("NFT Is not Eligible as a Collateral");
        }

        if (lender.currentAvailableLendAmount < borrower.innitialBorrowAmount) {
            revert("Not enough cash for Loan");
        }

        // freeze NFT
        nftCollateral.freeze(borrower.nftCollateralTokenId);

        // deduct loan amount from lender
        lender.currentAvailableLendAmount = lender
            .currentAvailableLendAmount
            .sub(borrower.innitialBorrowAmount);

        // set loan deadline
        borrower.deadline = block.timestamp.add(
            convertMonthsToSeconds(lender.loanDurationInMonthCount)
        );

        // add loan amount to borrower
        borrower.currentBorrowAmount = borrower.currentBorrowAmount.add(
            borrower.innitialBorrowAmount
        );
        borrower.isApproved = true;

        // transfer loan to msgSender
        (bool success, ) = msg.sender.call{
            value: borrower.innitialBorrowAmount
        }("");

        borrower.innitialBorrowAmount = borrower.innitialBorrowAmount.add(
            calculateLoanInterest(
                borrower.innitialBorrowAmount,
                lender.interestRate,
                lender.loanDurationInMonthCount
            )
        );

        if (!success) {
            revert TransferFailed();
        }
        emit LoanApproved(
            borrower.lenderId,
            _borrowerId,
            lender.lender,
            borrower.borrower,
            borrower.innitialBorrowAmount,
            borrower.deadline,
            borrower.currentBorrowAmount,
            borrower.isApproved
        );
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
        if (msg.value > borrower.currentBorrowAmount) {}

        // transfer amount to lender
        lender.currentAvailableLendAmount += msg.value;
        lender.amountRepaid += msg.value;

        // exonerate borrower
        borrower.amountAlreadyRemitted += msg.value;
        if (msg.value > borrower.currentBorrowAmount) {
            borrower.currentBorrowAmount = 0;
        }

        if (msg.value <= borrower.currentBorrowAmount) {
            borrower.currentBorrowAmount -= msg.value;
        }

        if (borrower.amountAlreadyRemitted >= borrower.innitialBorrowAmount) {
            borrower.isRepaid = true;
        }

        nftCollateral.unfreeze(borrower.nftCollateralTokenId);
        emit LoanRepayed(
            borrower.lenderId,
            borrower.borrowerId,
            lender.lender,
            borrower.borrower,
            msg.value,
            lender.currentAvailableLendAmount,
            lender.amountRepaid,
            borrower.amountAlreadyRemitted,
            borrower.currentBorrowAmount,
            borrower.isRepaid
        );
    }

    // liquidateCollateral
    /*
     * Liquidate collateral
     * puts nft on sale on the martkeplace
     *
     */
    function liquidateCollateral(
        uint256 _borrowerId,
        string memory _saleType
    ) public payable onlyWhenOverdue(_borrowerId) {
        // check that loan is overdue
        Borrower memory borrower = _borrowers[_borrowerId];
        Lender memory lender = _lenders[_borrowers[_borrowerId].lenderId];

        bytes32 practicalSaleType = keccak256(abi.encode(_saleType));

        // if liquidation sale type is public
        if (practicalSaleType == PUBLIC_SALE) {
            // implement listing asset on the marketplace
            return;
        }

        // implement private sale
        _liquidateInPrivateSale(
            _borrowers[_borrowerId].nftCollateralTokenId,
            _borrowerId,
            _borrowers[_borrowerId].lenderId
        );

        emit CollateralLiquidated(
            borrower.lenderId,
            _borrowerId,
            lender.lender,
            borrower.borrower,
            borrower.innitialBorrowAmount,
            msg.sender,
            lender.currentAvailableLendAmount,
            lender.amountRepaid,
            borrower.currentBorrowAmount,
            borrower.isRepaid,
            borrower.amountAlreadyRemitted
        );
    }

    // Liquidate private sale
    /*
     * unfreeze nft Collateral
     * transfer nft value to liquidator
     * repay lender
     * exonerate borrower
     */
    function _liquidateInPrivateSale(
        uint256 _nftCollateralTokenId,
        uint256 _borrowerId,
        uint256 _lenderId
    ) private {
        // unfreeze nft Collateral
        nftCollateral.unfreeze(_nftCollateralTokenId);

        Borrower storage borrower = _borrowers[_borrowerId];
        Lender storage lender = _lenders[_lenderId];

        if (msg.value < borrower.currentBorrowAmount) {
            revert("Liquidator Amount: insufficient funds");
        }

        // transfer nft value to liquidator
        nftCollateral.safeTransferFrom(
            borrower.borrower,
            msg.sender,
            _nftCollateralTokenId
        );
        // repay lender
        lender.currentAvailableLendAmount += msg.value; //available lend amount
        lender.amountRepaid += msg.value;

        // exonerate borrower
        if (msg.value > borrower.currentBorrowAmount) {
            borrower.currentBorrowAmount = 0;
            borrower.isRepaid = true;
        }

        if (msg.value <= borrower.currentBorrowAmount) {
            borrower.currentBorrowAmount -= msg.value;
        }
        borrower.amountAlreadyRemitted += msg.value;
    }

    // cancelLoan
    function cancelLoan(
        uint256 _lenderId
    ) public onlyLender(_lenders[_lenderId].lender) {
        _lenders[_lenderId].isActive = false;
        emit LoanCancelled(
            _lenderId,
            _lenders[_lenderId].lender,
            _lenders[_lenderId].innitialLendAmount,
            _lenders[_lenderId].isActive
        );
    }

    // update loan duration

    // add more funds
    function addfunds(
        uint256 _loanId
    ) public payable onlyLender(_lenders[_loanId].lender) {
        Lender storage lender = _lenders[_loanId];
        lender.currentAvailableLendAmount += msg.value;
        lender.innitialLendAmount += msg.value;

        emit FundsAdded(
            lender.currentAvailableLendAmount,
            lender.innitialLendAmount,
            _lenders[_loanId].lender,
            _loanId
        );
    }

    // deactivate loan

    function lockLoan(
        uint256 _loanId
    ) public payable onlyLender(_lenders[_loanId].lender) {
        _lenders[_loanId].locked = true;
        emit LoanLocked(_loanId, _lenders[_loanId].locked);
    }

    function unlockLoan(
        uint256 _loanId
    ) public payable onlyLender(_lenders[_loanId].lender) {
        _lenders[_loanId].locked = false;
        emit LoanUnLocked(_loanId, _lenders[_loanId].locked);
    }

    // fetch loan single
    function fetchLoanSingle(
        uint256 _loanId
    ) public view returns (Lender memory) {
        return _lenders[_loanId];
    }

    // fetch borrow single
    function fetchBorrowSingle(
        uint256 _borrowId
    ) public view returns (Borrower memory) {
        return _borrowers[_borrowId];
    }

    receive() external payable {}

    fallback() external payable {}
}
