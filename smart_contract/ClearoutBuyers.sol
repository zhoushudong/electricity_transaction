pragma solidity 0.4.11;

import "multiowned.sol";

contract ClearoutBuyers is multiowned {
    // TYPE
    struct _Power {
        uint256  peak;
        uint256  valley;
        uint256 flat;
    }
    
    // Fields
    mapping(address=>_Power) public initialMeter; //  record intial values of kilo-watt meters
    mapping(address=>_Power[]) public powers; // record kWh number of an address can use for m, m+1, m+2, m+3, ..., month
    mapping(address=>address[]) public ownMeters; // one buyer has several meters.
    mapping(address=>bool) public isMeter; // check if an address is a meter.
    
    
    // EVENT
    event SubmitPower(uint256 _power, uint256 _type);
    event WithdrawPower(uint256 _power, uint256 _type, address _meter, address _owner);
    
    // FUNCTION
    
    // name: construct
    function ClearoutBuyers(address[] _owners, uint _required) multiowned(_owners,_required) {
        
    }
    
    // name: submitPower
    // function: kilo-watt meter submit power to clear the POWER recorded so that the buyer can buy more for his meter.
    // input: 1. _power, uint256, amount of some POW asset.
    //        2. _type, uint256, type of POW asset.
    // return: bool, only for debug. 
    
    function submitPower(uint256 _power, uint256 _type) returns (bool) {
        if (! isMeter[msg.sender] ) {
            throw;
        }
        if (1==_type && powers[msg.sender][0].peak +_power >= initialMeter[0].peak )
        {
           powers[msg.sender][0].peak = 0;
           initialMeter[0].peak += _power;
           SubmitPower(_power, _type);
           return true;
        } else if (2==_type &&    powers[msg.sender][0].valley +_power >= initialMeter[0].valley){
            powers[msg.sender][0].valley = 0;
            initialMeter[0].valley += _power;
            SubmitPower(_power, _type);
           return true;
        } else if (3 == _type && powers[msg.sender][0].flat +_power >= initialMeter[0].flat){
            powers[msg.sender][0].flat = 0;
            initialMeter[0].flat += _power;
            SubmitPower(_power, _type);
           return true;
        }else {
            SubmitPower(0, 0);
            return false;
        }
        
    }
    
    // name: withdrawPower
    // function: The buyer withdraw his POW asset from stellar to the smart contract to record in ethereum
    // input: 1. _power, uint256, amount of some POW asset.
    //        2. _type, uint256, type of POW asset.
    //        3. _meter, the meter's address.
    // return: bool, only for debug. 
    
    function withdrawPower(uint256 _power, uint256 _type, address _meter, address _owner) onlymanyowners(sha3(msg.data)) returns (bool) {
        if (ownMeters[_owner][0] != _meter) {
            throw;
        }
        if (1==_type && 0==powers[_meter][0].peak) {
            powers[_meter][0].peak = _power;
            WithdrawPower(_power,_type,_meter,_owner);
            return true;
        } else if (2 == _type && 0==powers[_meter][0].valley) {
            powers[_meter][0].valley = _power;
            WithdrawPower(_power,_type,_meter,_owner);
            return true;
        } else if (3 == _type && 0==powers[_meter][0].flat) {
            powers[_meter][0].flat = _power;
            WithdrawPower(_power,_type,_meter,_owner);
            return true;
        } else {
            WithdrawPower(0,0,_meter,_owner);
            return false;
        }
        
    }
    
    // name: setIntialMeter
    // function: the intial value by meter
    // input: 1. _peak , uint 256
    //        2. _valley, uint256
    //        3. _flat, uint256
    
    function setIntialMeter(uint256 _peak, uint256 _valley, uint256 _flat) returns (bool) {
        if(!isMeter[msg.sender]) {
            throw;
        }
        initialMeter[msg.sender].peak = _peak;
        initialMeter[msg.sender].valley = _valley;
        initialMeter[msg.sender].flat = _flat;
        return true;
    }
    
}