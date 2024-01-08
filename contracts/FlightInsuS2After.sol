 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightInsurance {
    address public owner;
    address public admin;
    uint256 public fixedInsuredAmount; // Fixed insured amount set in the constructor
    uint256 public delayThreshold; // Threshold for delay in hours
    uint256 public delayTime; // Actual delay time in hours

    enum ClaimStatus { NotStarted, Pending, Approved, Denied }
    mapping(address => mapping(uint256 => bool)) public hasPurchasedInsurance;
    mapping(address => mapping(uint256 => ClaimStatus)) public claimStatus;
    mapping(address => mapping(uint256 => uint256)) public insuredAmounts;
    mapping(address => mapping(uint256 => uint256)) public ticketPrices;
    mapping(address => mapping(uint256 => string)) public claimJustification;

    event InsurancePurchased(address indexed claimant, uint256 flightNumber, uint256 insuredAmount, uint256 ticketPrice);
    event ClaimAmountCalculated(address indexed claimant, uint256 flightNumber, uint256 claimAmount, string Policy);
    event ClaimProcessed(address indexed claimant, uint256 flightNumber, uint256 claimAmount, uint256 delayTime, ClaimStatus status);
    event ClaimDenied(address indexed claimant, uint256 flightNumber, string justification);
    event DelayThresholdSet(uint256 threshold);
    event DelayTimeSet(uint256 time);
    event AdminSet(address adminAddress, string justification);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can execute this");
        _;
    }
    constructor(uint256 _fixedInsuredAmount) {
        owner = msg.sender;
        fixedInsuredAmount = _fixedInsuredAmount;
        delayThreshold = 2; // Default threshold for delay in hours
    }
    function setAdmin(address _admin, string memory justification) public onlyOwner {
        require(_admin != address(0), "Invalid admin address");
        admin = _admin;
        emit AdminSet(_admin, justification);
    }
    function purchaseInsurance(uint256 flightNumber, uint256 ticketPrice) public payable {
        require(!hasPurchasedInsurance[msg.sender][flightNumber], "Insurance already purchased for this flight");
        require(msg.value >= fixedInsuredAmount, "Incorrect amount sent");

        // Store insured amount and ticket price for the specific claimant and flight number
        insuredAmounts[msg.sender][flightNumber] = fixedInsuredAmount;
        ticketPrices[msg.sender][flightNumber] = ticketPrice;
        hasPurchasedInsurance[msg.sender][flightNumber] = true;

        emit InsurancePurchased(msg.sender, flightNumber, fixedInsuredAmount, ticketPrice);
    }
    function calculateClaimAmount(uint256 flightNumber) public  returns (uint256) {
         
        uint256 insuredAmount = insuredAmounts[msg.sender][flightNumber];
        require(insuredAmount > 0, "No insured amount set for the claimant and flight");

        // Get the stored ticket price for the claimant and flight number
        uint256 ticketPrice = ticketPrices[msg.sender][flightNumber];
        require(ticketPrice > 0, "No ticket price stored for the claimant and flight");

        // Calculate claim amount as 10% of the ticket price
        uint256 claimAmount = (ticketPrice * 10) / 100;
        emit ClaimAmountCalculated(msg.sender,  flightNumber,  claimAmount, "10% of ticket price if delay more than 2 hours");
        return claimAmount;
    }
    function processClaim(uint256 flightNumber) public {

        uint256 claimAmount = calculateClaimAmount(flightNumber);

        // Update claim status to Pending
        claimStatus[msg.sender][flightNumber] = ClaimStatus.Pending;

        emit ClaimProcessed(msg.sender, flightNumber, claimAmount, delayTime, ClaimStatus.Pending);

    }
    function approveClaim(address claimant, uint256 flightNumber) public onlyAdmin {
        require(hasPurchasedInsurance[claimant][flightNumber], "No insurance purchased for this flight");
        require(claimStatus[claimant][flightNumber] == ClaimStatus.Pending);

        uint256 claimAmount = calculateClaimAmount(flightNumber);

        // Transfer funds to the claimant if the claim is approved
        if (claimAmount > 0) {
        payable(claimant).transfer(claimAmount);
        }

    // Update claim status to Approved if claimAmount > 0, else Denied
    claimStatus[claimant][flightNumber] = (claimAmount > 0) ? ClaimStatus.Approved : ClaimStatus.Denied;

    emit ClaimProcessed(claimant, flightNumber, claimAmount, delayTime, claimStatus[claimant][flightNumber]);
    }
    function denyClaim(address claimant, uint256 flightNumber, string memory justification) public onlyAdmin {
        require(claimStatus[claimant][flightNumber] == ClaimStatus.Pending, "Claim not in pending state");

        // Update claim status to Denied
        claimStatus[claimant][flightNumber] = ClaimStatus.Denied;

        emit ClaimProcessed(claimant, flightNumber, 0, delayTime, ClaimStatus.Denied);
        emit ClaimDenied(claimant, flightNumber, justification);

        // Store the justification for denying the claim
        claimJustification[claimant][flightNumber] = justification;
    }
    function setDelayThreshold(uint256 _delayThreshold) public onlyOwner {
        delayThreshold = _delayThreshold;
        emit DelayThresholdSet(_delayThreshold);
    }
    function setDelayTime(uint256 _delayTime) public onlyOwner {
        delayTime = _delayTime;
        emit DelayTimeSet(_delayTime);
    }

}
 
