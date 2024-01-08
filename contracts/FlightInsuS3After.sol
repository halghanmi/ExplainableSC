 // SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract DelayThresholdVoting {
    address public owner;
    uint256 public currentThreshold;
    uint256 public newThreshold;
    uint256 public votingDuration;
    uint256 public votingEndTime;
    address[] public stakeholderList;
    mapping(address => bool) public stakeholders;
    mapping(address => bool) public hasVoted;
    uint256 public yesVotes;
    uint256 public noVotes;
    uint256 public votingThresholdPercent;

    event VotingStarted(uint256 newThreshold, uint256 endTime, uint256 votingDuration, uint256 votingThresholdPercent);
    event Voted(address indexed voter, bool inFavor);
    event VotingCompleted(uint256 currentThreshold, uint256 newThreshold, bool changeAccepted, uint256 yesVotes, uint256 noVotes);
    event StakeholderAdded(address newStakeholder);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }
    modifier onlyStakeholder() {
        require(stakeholders[msg.sender], "Only stakeholders can execute this");
        _;
    }
    constructor(uint256 initialThreshold, uint256 durationInDays, uint256 thresholdPercent) {
        owner = msg.sender;
        currentThreshold = initialThreshold;
        newThreshold = initialThreshold; // Initialize new threshold with the current threshold
        votingDuration = durationInDays * 1 days;
        votingEndTime = 0;
        votingThresholdPercent = thresholdPercent;
    }
    function getVotingDetails() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (newThreshold, votingEndTime, block.timestamp, votingDuration, yesVotes, noVotes, votingThresholdPercent);
    }
    function startVoting(uint256 proposedThreshold) public onlyOwner {
        require(block.timestamp > votingEndTime, "Voting is still in progress");
        require(proposedThreshold != currentThreshold, "New threshold must be different");

        newThreshold = proposedThreshold;
        votingEndTime = block.timestamp + votingDuration;
        yesVotes = 0;
        noVotes = 0;

        emit VotingStarted(newThreshold, votingEndTime, votingDuration, votingThresholdPercent);
    }
    function vote(bool inFavor) public onlyStakeholder {
        require(block.timestamp <= votingEndTime, "Voting has ended");
        require(!hasVoted[msg.sender], "You have already voted");
        hasVoted[msg.sender] = true;
        if (inFavor) {
            yesVotes++;
        } else {
            noVotes++;
        }
        emit Voted(msg.sender, inFavor);
    }
    function endVoting() public onlyOwner {
        require(block.timestamp > votingEndTime, "Voting is still in progress");
        uint256 totalStakeholders = countStakeholders();
        bool changeAccepted = (yesVotes * 100) >= (totalStakeholders * votingThresholdPercent);
        uint256 oldThreshold = currentThreshold; 
        if (changeAccepted) {
            currentThreshold = newThreshold; // Update current threshold with the new one
        }
        emit VotingCompleted(oldThreshold, currentThreshold, changeAccepted, yesVotes, noVotes);
    }
    function addStakeholder(address newStakeholder) public onlyOwner {
        require(!stakeholders[newStakeholder], "Stakeholder already added");
        stakeholders[newStakeholder] = true;
        stakeholderList.push(newStakeholder);
        emit StakeholderAdded(newStakeholder);
    }
    function countStakeholders() public view returns (uint256) {
        return stakeholderList.length;
    }
}
