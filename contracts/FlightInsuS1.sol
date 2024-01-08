  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightInsurance {
    address public owner;
    uint256 public fixedInsuredAmount;
    uint256 public delayThreshold; // Threshold for delay in hours
    uint256 public delayTime; // for domonstration only, the delay time should be reterive from external resources.

    mapping(address => mapping(uint256 => bool)) public hasPurchasedInsurance;
    mapping(address => mapping(uint256 => bool)) public claimStatus;
    mapping(address => mapping(uint256 => uint256)) public insuredAmounts;
    mapping(address => mapping(uint256 => uint256)) public ticketPrices;

    

    modifier onlyOwner() {
        require(msg.sender == owner, "Only  owner");
        _;
    }

    constructor(uint256 _fixedInsuredAmount) {
        owner = msg.sender;
        fixedInsuredAmount = _fixedInsuredAmount;
        delayThreshold = 2; // Default threshold for delay in hours
    }

    // Store insured amount and ticket price for the specific claimant and flight number
    function purchaseInsurance(uint256 flightNumber, uint256 ticketPrice) public payable {
        require(!hasPurchasedInsurance[msg.sender][flightNumber]);
        require(msg.value >= fixedInsuredAmount );

        
        insuredAmounts[msg.sender][flightNumber] = fixedInsuredAmount;
        ticketPrices[msg.sender][flightNumber] = ticketPrice;
        hasPurchasedInsurance[msg.sender][flightNumber] = true;

    }

    function calculateClaimAmount(uint256 flightNumber) public view returns (uint256) {
        require(hasPurchasedInsurance[msg.sender][flightNumber], "No insurance purchased for this flight");
        require(!claimStatus[msg.sender][flightNumber], "Approved before");

        uint256 insuredAmount = insuredAmounts[msg.sender][flightNumber];
        require(insuredAmount > 0);

        // Get the stored ticket price for the claimant and flight number
        uint256 ticketPrice = ticketPrices[msg.sender][flightNumber];
        require(ticketPrice > 0);

        // Calculate claim amount as 10% of the ticket price
        uint256 claimAmount = (ticketPrice * 10) / 100;

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

    }

    function setDelayThreshold(uint256 _delayThreshold) public onlyOwner {
        delayThreshold = _delayThreshold;
        
    }
    // manual insertion of the flight delay time for the purpose of this example,
    function setDelayTime(uint256 _delayTime) public onlyOwner {
        delayTime = _delayTime;
        
    }
}

/*
This is a simple example, and in practical applications, the delay time would typically be obtained 
from an oracle service, utilizing a link such as the 'https://api.flightstats.com/...' However, 
integrating with oracles requires additional efforts, including setting up the oracle integration, 
writing code in the smart contract to make oracle calls, configuring parameters like the oracle's 
address and job ID, ensuring security measures, testing thoroughly, and involving associated fees. 
For the purposes of this example, we are focusing solely on the smart contract itself.
*/

}
