pragma solidity 0.4.11;

import "multiowned.sol";

contract ClearoutSellers is multiowned {
    // TYPE
    struct _Power {
        uint256  peak;
        uint256  pre_peak_value;
        uint256  valley;
        uint256  pre_valley_value;
        uint256 flat;
        uint256 pre_flat_value;
    }
    
    // Fields
    mapping(address=>_Power) public initialMeter; //  record intial values of kilo-watt meters
    mapping(address=>_Power[]) public powers; // record kWh number of an address can use for m, m+1, m+2, m+3, ..., month
    //mapping(address=>address[]) public ownMeters; // one buyer has several meters.
    mapping(address=>uint256) public isMeter; // check if an address is a meter (2^^255 represents this an address is a meter, other number <1000*10^8 represents ).
    
    
    // EVENT
    event SubmitPower(uint256 _power, uint256 _type);
    event WithdrawToken(uint256 value, address _meter);
    event SetInitialMeter(uint256 _peak, uint256 _valley, uint256 _flat);
    event Presale(uint256 _electricity, uint256 _type, address _meter);
    
    // FUNCTION
    
    // construct
    
    
    // name: submitPower
    // function: kilo-watt meter submit power to clear the POWER recorded so that the buyer can buy more for his meter.
    // input: 1. _power, uint256, amount of some POW asset.
    //        2. _type, uint256, type of POW asset.
    // return: bool, only for debug. 
    
    function submitPower(uint256 _power, uint256 _type) returns (bool) {
        if (2**255 != isMeter[msg.sender] ) {
            throw;
        }
        if (1==_type &&  _power - initialMeter[0].peak  >=  powers[msg.sender][0].peak )
        {
           
           initialMeter[0].peak += powers[msg.sender][0].peak;
           powers[msg.sender][0].peak = 0;
           //  transfer tokens
           
           SubmitPower(_power, _type);
           return true;
        } else if (2==_type &&   _power - initialMeter[0].valley  >= powers[msg.sender][0].valley  ){
            
            initialMeter[0].valley += powers[msg.sender][0].valley;
            powers[msg.sender][0].valley = 0;
            // transfer tokens
            
            SubmitPower(_power, _type);
           return true;
        } else if (3 == _type &&  _power - initialMeter[0].flat  >= powers[msg.sender][0].flat ){
            
            initialMeter[0].flat += powers[msg.sender][0].flat;
            powers[msg.sender][0].flat = 0;
            // transfer tokens
            
            SubmitPower(_power, _type);
           return true;
        }else {
            SubmitPower(0, 0);
            return false;
        }
        
    }
    
    // name: withdrawToken
    // function: The buyer withdraw his POW asset from stellar to the smart contract to record in ethereum
    // input: 1. _power, uint256, amount of some POW asset.
    //        2. _type, uint256, type of POW asset.
    //        3. _meter, the meter's address.
    // return: bool, only for debug. 
    
    function withdrawToken(uint256 _value,  address _meter) onlymanyowners(sha3(msg.data)) returns (bool) {
        if(0==isMeter[_meter]) {
            throw;
        }
        isMeter[_meter] = _value;
        WithdrawToken(_value, _meter);
        return true;
    }
    
    // name: setIntialMeter
    // function: the intial value by meter
    // input: 1. _peak , uint 256
    //        2. _valley, uint256
    //        3. _flat, uint256
    
    function setIntialMeter(uint256 _peak, uint256 _valley, uint256 _flat) returns (bool) {
        if(0==isMeter[msg.sender]) {
            throw;
        }
        initialMeter[msg.sender].peak = _peak;
        initialMeter[msg.sender].valley = _valley;
        initialMeter[msg.sender].flat = _flat;
        SetInitialMeter(_peak, _valley, _flat);
        return true;
    }
    
    function presale(uint256 _electricity, uint256 _type, address _meter) onlymanyowners(sha3(msg.data)) returns (bool) {
        if(0==isMeter[_meter]) {
            throw;
        }
        
        
        if (1== _type  ) {
            powers[_meter][0].pre_peak_value = _electricity;
            Presale(_electricity,_type, _meter);
            return true;
        } else if ( 2== _type ) {
            powers[_meter][0].pre_valley_value = _electricity;
            Presale(_electricity,_type, _meter);
            return true;
        } else if ( 3== _type ) {
            powers[_meter][0].pre_flat_value = _electricity;
            Presale(_electricity,_type, _meter);
            return true;
        } else {
            Presale(0, 0, _meter);
            return false;
        }
        
    }
    
}