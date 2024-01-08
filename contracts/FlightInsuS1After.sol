// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightInsurance {
    address public owner;
    uint256 public fixedInsuredAmount; // Fixed insured amount set in the constructor
    uint256 public delayThreshold; // Threshold for delay in hours
    uint256 public delayTime; // Actual delay time in hours

    mapping(address => mapping(uint256 => bool)) public hasPurchasedInsurance;
    mapping(address => mapping(uint256 => bool)) public claimStatus;
    mapping(address => mapping(uint256 => uint256)) public insuredAmounts;
    mapping(address => mapping(uint256 => uint256)) public ticketPrices;

    event InsurancePurchased(address indexed claimant, uint256 flightNumber, uint256 insuredAmount, uint256 ticketPrice);
    event ClaimAmountCalculated(address indexed claimant, uint256 flightNumber, uint256 claimAmount, string Policy);
    event ClaimProcessed(address indexed claimant, uint256 flightNumber, uint256 claimAmount, uint256 delayTime, bool isApproved);
    event DelayThresholdSet(uint256 threshold);
    event DelayTimeSet(uint256 time);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }

    constructor(uint256 _fixedInsuredAmount) {
        owner = msg.sender;
        fixedInsuredAmount = _fixedInsuredAmount;
        delayThreshold = 2; // Default threshold for delay in hours
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

    function calculateClaimAmount(uint256 flightNumber) public returns (uint256) {
        require(hasPurchasedInsurance[msg.sender][flightNumber], "No insurance purchased for this flight");
        require(!claimStatus[msg.sender][flightNumber], "Claim already approved or denied");

        uint256 insuredAmount = insuredAmounts[msg.sender][flightNumber];
        require(insuredAmount > 0, "No insured amount set for the claimant and flight");

        // Get the stored ticket price for the claimant and flight number
        uint256 ticketPrice = ticketPrices[msg.sender][flightNumber];
        require(ticketPrice > 0, "No ticket price stored for the claimant and flight");

        // Calculate claim amount as 10% of the ticket price
        uint256 claimAmount = (ticketPrice * 10) / 100;
        emit ClaimAmountCalculated(msg.sender, flightNumber, claimAmount, "10% of ticket price");
        return claimAmount;
    }

    function processClaim(uint256 flightNumber) public {
        require(!claimStatus[msg.sender][flightNumber], "Claim already approved or denied");

        uint256 claimAmount = calculateClaimAmount(flightNumber);

        // Transfer funds to the claimant if the claim is approved
        if (claimAmount > 0) {
            payable(msg.sender).transfer(claimAmount);
        }

        // Update claim status to true (approved) if claimAmount > 0, else false (denied)
        claimStatus[msg.sender][flightNumber] = (claimAmount > 0);

        emit ClaimProcessed(msg.sender, flightNumber, claimAmount, delayTime, claimStatus[msg.sender][flightNumber]);
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
