pragma solidity ^0.4.16;

contract Etherlife {
    address public owner; // owner du smart contract
    uint256 public lastTimePing; // la dernière fois que le owner a fait ping
    uint256 public timeBeforeInactivity; // en secondes
    uint256 public timeFirstClaim; // Time of the first claim
    address public lowestClaimer; // Address of the claimer with the lowest rank
    
    
    uint256 public amount;
    
    /* Data structure Beneficiary */
    struct Beneficiary {
        address addressBeneficiary;
        uint256 part;
        uint256 amountBeneficiary;
        bool claimed;
        address parentBefeficiary;
    }
    Beneficiary[] public beneficiaries; // liste des bénéficiaires en tant que héritiers de l'assurance vie
    
    function Etherlife(uint256 _timeBeforeInactivity) payable {
        owner = msg.sender;
        timeBeforeInactivity = _timeBeforeInactivity; // si le owner ne ping pas au bout de 5 min, il est mort
        amount = msg.value;
        lastTimePing = now;
    }
    
    //modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
        lastTimePing = now;
    }
    
    modifier onlyActiveOwner() {
        require(!inactive());
        _;
    }
    
    modifier onlyInactiveOwner() {
        require(inactive());
        _;
    }
    
    // Events - logs
    event AddBeneficiaryEvent(
        address indexed beneficiary,
        uint256 part,
        uint256 amountBeneficiary,
        bool claimed,
        address parentBeneficiary
    );
    
    event SetTimeBeforeInactivityEvent(
        uint256 _timeBeforeInactivity
    );
    
    event ClaimEvent(
        address beneficiary,
        uint256 amount,
        bool claimed
    );

    
    /*
    * Etape n° 1)
    * function: addBeneficiary
    * Scope: owner seul pourra ajouter de bénéficiaire
    */
    function addBeneficiary(address _addressBeneficiary, uint256 _part)
        onlyOwner
        returns(bool success) {
            
        Beneficiary memory beneficiary;
        
        beneficiary.addressBeneficiary = _addressBeneficiary;
        beneficiary.part = _part;
        beneficiary.amountBeneficiary = (amount*_part)/100;
        beneficiary.claimed = false;
        
        beneficiary.parentBefeficiary = owner;
        
        beneficiaries.push(beneficiary);
        
        AddBeneficiaryEvent(
            beneficiary.addressBeneficiary,
            beneficiary.part,
            beneficiary.amountBeneficiary,
            beneficiary.claimed,
            beneficiary.parentBefeficiary
        );
        
        return true;
        
    }
    
    /*
    * Etape n°2 (Optionnel)
    * function : at tout moment le owner pourra mettre à jour _timeBeforeInactivity
    * a partir du quel il sera considérer comme mort
    */
    function setTimeBeforeInactivity(uint256 _timeBeforeInactivity)
        onlyOwner
        onlyActiveOwner
        returns(bool success) {
        
        timeBeforeInactivity = _timeBeforeInactivity;
        
        SetTimeBeforeInactivityEvent(_timeBeforeInactivity);
    
        return true;
    }
    
    
    /// Return true if the owner is inactive for at least.
    function inactive()
        constant
        returns (bool) {
            
        if (now < lastTimePing + timeBeforeInactivity) // Not enough time since last ping
            return false;
            
        if (lastTimePing + timeBeforeInactivity < lastTimePing) // Overflow
            return false;
            
        return true; // If nothing is wrong, the owner is inactive.
    }
    
    
    // Claim the control of the contract
    // Verify that the owner is inactive
    function claim()
        onlyInactiveOwner
        returns(bool success){
        
        for(uint index=0; index<beneficiaries.length; index++) {
            
            // Verify that the claimer is a beneficiary
            // Not already made a claim
            if(beneficiaries[index].addressBeneficiary == msg.sender && beneficiaries[index].claimed == false){
                
                
                beneficiaries[index].claimed = true;
                
                lowestClaimer=beneficiaries[index].addressBeneficiary;
                
                if(beneficiaries[index].addressBeneficiary.send(beneficiaries[index].amountBeneficiary)) {
                    amount -= beneficiaries[index].amountBeneficiary;
                    
                    ClaimEvent(
                        beneficiaries[index].addressBeneficiary,
                        beneficiaries[index].amountBeneficiary,
                        beneficiaries[index].claimed
                    );
                }
                
                return true;
                
            }
        }
        
        return false;
        
    }
    
    function () payable {}
    
}