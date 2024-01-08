// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightInsurance {
    address public owner;
    address public admin;
    uint256 public fixedInsuredAmount; 
    uint256 public delayThreshold; 
    uint256 public delayTime; 

    enum ClaimStatus { NotStarted, Pending, Approved, Denied }
    mapping(address => mapping(uint256 => bool)) public hasPurchasedInsurance;
    mapping(address => mapping(uint256 => ClaimStatus)) public claimStatus;
    mapping(address => mapping(uint256 => uint256)) public insuredAmounts;
    mapping(address => mapping(uint256 => uint256)) public ticketPrices;



    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(uint256 _fixedInsuredAmount) {
        owner = msg.sender;
        fixedInsuredAmount = _fixedInsuredAmount;
        delayThreshold = 2; // Default threshold for delay in hours
    }

    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0));
        admin = _admin;
    }

    function purchaseInsurance(uint256 flightNumber, uint256 ticketPrice) public payable {
        require(!hasPurchasedInsurance[msg.sender][flightNumber]);
        require(msg.value >= fixedInsuredAmount);

        // Store insured amount and ticket price for the specific claimant and flight number
        insuredAmounts[msg.sender][flightNumber] = fixedInsuredAmount;
        ticketPrices[msg.sender][flightNumber] = ticketPrice;
        hasPurchasedInsurance[msg.sender][flightNumber] = true;

       
    }

    function calculateClaimAmount(uint256 flightNumber) public view returns (uint256) {
    

    uint256 insuredAmount = insuredAmounts[msg.sender][flightNumber];
    require(insuredAmount > 0, "No insured amount set for the claimant and flight");

    // Get the stored ticket price for the claimant and flight number
    uint256 ticketPrice = ticketPrices[msg.sender][flightNumber];
    require(ticketPrice > 0, "No ticket price stored for the claimant and flight");

    // Calculate claim amount as 10% of the ticket price
    uint256 claimAmount = (ticketPrice * 10) / 100;

    return claimAmount;
}

    function processClaim(uint256 flightNumber) public {
        
        claimStatus[msg.sender][flightNumber] = ClaimStatus.Pending;
        uint256 claimAmount = calculateClaimAmount(flightNumber);
        

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

    }

    function denyClaim(address claimant, uint256 flightNumber) public onlyAdmin {
        require(claimStatus[claimant][flightNumber] == ClaimStatus.Pending);

        // Update claim status to Denied
        claimStatus[claimant][flightNumber] = ClaimStatus.Denied;
    }

    function setDelayThreshold(uint256 _delayThreshold) public onlyOwner {
        delayThreshold = _delayThreshold;
    }

    function setDelayTime(uint256 _delayTime) public onlyOwner {
        delayTime = _delayTime;
    }

    function getDelayThreshold() public view returns (uint256) {
        return delayThreshold;
    }

    function getDelayTime() public view returns (uint256) {
        return delayTime;
    }
}
