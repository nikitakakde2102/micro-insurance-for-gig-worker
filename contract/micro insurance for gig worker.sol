// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MicroInsuranceForGigWorker
 * @dev A decentralized micro insurance platform for gig workers
 * @author Micro Insurance Team
 */
contract MicroInsuranceForGigWorker {
    
    // State variables
    address public owner;
    uint256 public totalPolicies;
    uint256 public totalClaims;
    
    // Insurance policy structure
    struct Policy {
        uint256 policyId;
        address worker;
        uint256 premium;
        uint256 coverageAmount;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        string workType; // e.g., "delivery", "rideshare", "freelance"
    }
    
    // Claim structure
    struct Claim {
        uint256 claimId;
        uint256 policyId;
        address claimant;
        uint256 claimAmount;
        string reason;
        bool isApproved;
        bool isPaid;
        uint256 claimTime;
    }
    
    // Mappings
    mapping(uint256 => Policy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(address => uint256[]) public workerPolicies;
    mapping(address => uint256) public workerBalances;
    
    // Events
    event PolicyPurchased(uint256 indexed policyId, address indexed worker, uint256 premium, uint256 coverage);
    event ClaimSubmitted(uint256 indexed claimId, uint256 indexed policyId, address indexed claimant, uint256 amount);
    event ClaimApproved(uint256 indexed claimId, uint256 amount);
    event ClaimPaid(uint256 indexed claimId, address indexed claimant, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validPolicy(uint256 _policyId) {
        require(_policyId <= totalPolicies && _policyId > 0, "Invalid policy ID");
        require(policies[_policyId].isActive, "Policy is not active");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalPolicies = 0;
        totalClaims = 0;
    }
    
    /**
     * @dev Core Function 1: Purchase Insurance Policy
     * @param _coverageAmount The amount of coverage desired
     * @param _duration Duration of policy in seconds
     * @param _workType Type of gig work (delivery, rideshare, etc.)
     */
    function purchasePolicy(
        uint256 _coverageAmount,
        uint256 _duration,
        string memory _workType
    ) external payable {
        require(_coverageAmount > 0, "Coverage amount must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(msg.value > 0, "Premium must be paid");
        
        // Calculate premium (simplified: 2% of coverage amount)
        uint256 expectedPremium = (_coverageAmount * 2) / 100;
        require(msg.value >= expectedPremium, "Insufficient premium paid");
        
        totalPolicies++;
        
        policies[totalPolicies] = Policy({
            policyId: totalPolicies,
            worker: msg.sender,
            premium: msg.value,
            coverageAmount: _coverageAmount,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            isActive: true,
            workType: _workType
        });
        
        workerPolicies[msg.sender].push(totalPolicies);
        
        emit PolicyPurchased(totalPolicies, msg.sender, msg.value, _coverageAmount);
    }
    
    /**
     * @dev Core Function 2: Submit Insurance Claim
     * @param _policyId The policy ID for which claim is being made
     * @param _claimAmount Amount being claimed
     * @param _reason Reason for the claim
     */
    function submitClaim(
        uint256 _policyId,
        uint256 _claimAmount,
        string memory _reason
    ) external validPolicy(_policyId) {
        Policy storage policy = policies[_policyId];
        require(policy.worker == msg.sender, "Only policy holder can submit claim");
        require(block.timestamp <= policy.endTime, "Policy has expired");
        require(_claimAmount <= policy.coverageAmount, "Claim amount exceeds coverage");
        require(bytes(_reason).length > 0, "Claim reason is required");
        
        totalClaims++;
        
        claims[totalClaims] = Claim({
            claimId: totalClaims,
            policyId: _policyId,
            claimant: msg.sender,
            claimAmount: _claimAmount,
            reason: _reason,
            isApproved: false,
            isPaid: false,
            claimTime: block.timestamp
        });
        
        emit ClaimSubmitted(totalClaims, _policyId, msg.sender, _claimAmount);
    }
    
    /**
     * @dev Core Function 3: Process and Pay Claims
     * @param _claimId The claim ID to process
     * @param _approve Whether to approve or reject the claim
     */
    function processClaim(uint256 _claimId, bool _approve) external onlyOwner {
        require(_claimId <= totalClaims && _claimId > 0, "Invalid claim ID");
        
        Claim storage claim = claims[_claimId];
        require(!claim.isPaid, "Claim already paid");
        
        if (_approve) {
            require(address(this).balance >= claim.claimAmount, "Insufficient contract balance");
            
            claim.isApproved = true;
            claim.isPaid = true;
            
            // Transfer claim amount to claimant
            payable(claim.claimant).transfer(claim.claimAmount);
            
            emit ClaimApproved(_claimId, claim.claimAmount);
            emit ClaimPaid(_claimId, claim.claimant, claim.claimAmount);
        }
    }
    
    // Additional utility functions
    
    /**
     * @dev Get policy details
     * @param _policyId Policy ID to query
     */
    function getPolicyDetails(uint256 _policyId) external view returns (
        address worker,
        uint256 premium,
        uint256 coverageAmount,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        string memory workType
    ) {
        Policy storage policy = policies[_policyId];
        return (
            policy.worker,
            policy.premium,
            policy.coverageAmount,
            policy.startTime,
            policy.endTime,
            policy.isActive,
            policy.workType
        );
    }
    
    /**
     * @dev Get claim details
     * @param _claimId Claim ID to query
     */
    function getClaimDetails(uint256 _claimId) external view returns (
        uint256 policyId,
        address claimant,
        uint256 claimAmount,
        string memory reason,
        bool isApproved,
        bool isPaid,
        uint256 claimTime
    ) {
        Claim storage claim = claims[_claimId];
        return (
            claim.policyId,
            claim.claimant,
            claim.claimAmount,
            claim.reason,
            claim.isApproved,
            claim.isPaid,
            claim.claimTime
        );
    }
    
    /**
     * @dev Get worker's policy IDs
     * @param _worker Worker address
     */
    function getWorkerPolicies(address _worker) external view returns (uint256[] memory) {
        return workerPolicies[_worker];
    }
    
    /**
     * @dev Check contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Emergency withdraw function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    /**
     * @dev Receive function to accept Ether
     */
    receive() external payable {}
}
