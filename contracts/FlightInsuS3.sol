 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DelayThresholdVoting {
    address public owner;
    uint256 public currentThreshold;
    uint256 public votingDuration;
    uint256 public votingEndTime;
    mapping(address => bool) public stakeholders;
    mapping(address => bool) public hasVoted;
    uint256 public yesVotes;
    uint256 public noVotes;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    modifier onlyStakeholder() {
        require(stakeholders[msg.sender], "Only stakeholder");
        _;
    }
    constructor(uint256 initialThreshold, uint256 durationInMinutes) {
        owner = msg.sender;
        currentThreshold = initialThreshold;
        votingDuration = durationInMinutes * 1 minutes;
        votingEndTime = 0;
    }
    function startVoting(uint256 newThreshold) public onlyOwner {
        require(block.timestamp > votingEndTime, " In progress");
        require(newThreshold != currentThreshold, "same threshold");

        votingEndTime = block.timestamp + votingDuration;
        yesVotes = 0;
        noVotes = 0; 
    }
    function vote(bool inFavor) public onlyStakeholder {
        require(block.timestamp <= votingEndTime);
        require(!hasVoted[msg.sender]);
        hasVoted[msg.sender] = true;
        if (inFavor) { yesVotes++; } else { noVotes++;}     
    }
    function endVoting() public onlyOwner {
        require(block.timestamp > votingEndTime, "In progress");
        bool changeAccepted = yesVotes > noVotes;
        if (changeAccepted) {
            currentThreshold = currentThreshold;
        }  
    }
    function addStakeholder(address newStakeholder) public onlyOwner {
        require(!stakeholders[newStakeholder], "Stakeholder already added");
        stakeholders[newStakeholder] = true;
        
    }
}
