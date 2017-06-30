pragma solidity 0.4.11;

import "multiowned.sol";

contract ClearoutSellers is multiowned {
    // TYPE
    struct _Power {
        uint256  peak; // record the amount of peak power to sell
        uint256  pre_peak_value; // record the number of the tokens to sell the amount of peak
        uint256  valley;
        uint256  pre_valley_value;
        uint256 flat;
        uint256 pre_flat_value;
    }
    
    // Fields
    uint256 public constant numAsset = 12 ; // the total number of power asset: m, m+1, m+2, m+3, ..., m+numAsset -1;
    mapping(address=>_Power) public initialMeter; //  record intial values of kilo-watt meters
    mapping(address=>_Power[12]) public powers; // record kWh number of an address can use for m, m+1, m+2, m+3, ..., month
    mapping(address=>address[]) public ownMeters; // one seller has several meters.
    mapping(address=>uint256) public tokens; // record the tokens of one user holds.
    mapping(address=>bool) public isMeter; // check if an address is a meter .
    mapping(address=>bool) public isMeterOpened; // check if a meter is already opened after being installed.
    
    
    // EVENT
    event SubmitPower(uint256 _power, uint256 _type);
    event WithdrawToken(uint256 _value, address _meter);
    event SetInitialMeter(uint256 _peak, uint256 _valley, uint256 _flat);
    event Presale(uint256 _electricity, uint256 _type, address _meter);
    event IsMeterOpened(bool _status, address _meter);
    
    // FUNCTION
    
    // construct
    function ClearoutSellers(address[] _owners, uint _required) multiowned(_owners,_required) {
        
    }
    
    // name: setMeterOwner
    // function: set the owner of a meter, and register the meter, that is, set isMeter true.
    // input: 1. _meter, address, the ethereum account address of a meter.
    //        2. _seqMeter, refer the sequence of the meter owned by the _owner.
    
    function setMeterOwner(address _meter, address _owner) onlymanyowners(sha3(msg.data)) returns (bool) {
        ownMeters[_owner].push( _meter);
        isMeter[_meter] = true;
        return true;
    }

    // name: meterOpened
    // function: submit the phsical status of a meter
    // input: 1. _status, bool
    
    function meterOpened(bool _status) returns (bool) {
        if (!isMeter[msg.sender]) {
            throw;
        }

        isMeterOpened[msg.sender] = _status;
        IsMeterOpened(_status,msg.sender);
        return true;
    }
    
    // name: submitPower
    // function: kilo-watt meter submit power to clear the POWER recorded so that the buyer can buy more for his meter.
    // input: 1. _power, uint256, amount of some POW asset.
    //        2. _type, uint256, type of POW asset.
    //        3. _seqMeter, uint256, the sequence of a meter.
    //        4. _seq, the sequence to sell the power asset of type _type, this parameter to determine the location of store.
    //        5. _owner, address, the owner of a meter.
    // return: bool, only for debug. 
    
    function submitPower(uint256 _power, uint256 _type, uint256 _seqMeter, uint256 _seq, address _owner) returns (bool) {
        if (!isMeter[msg.sender] ) {
            throw;
        }
        if (ownMeters[_owner][_seqMeter] != msg.sender) {
            throw;
        }
        if (1==_type &&  _power - initialMeter[msg.sender].peak  >=  powers[msg.sender][_seq%numAsset].peak )
        {
           initialMeter[msg.sender].peak += powers[msg.sender][_seq%numAsset].peak;
           powers[msg.sender][_seq%numAsset].peak = 0;
           //  transfer tokens
           tokens[_owner] += powers[msg.sender][_seq%numAsset].pre_peak_value;
           powers[msg.sender][_seq%numAsset].pre_peak_value = 0;
           SubmitPower(_power, _type);
           return true;
        } else if (2==_type &&   _power - initialMeter[msg.sender].valley  >= powers[msg.sender][_seq%numAsset].valley  ){
            initialMeter[msg.sender].valley += powers[msg.sender][_seq%numAsset].valley;
            powers[msg.sender][_seq%numAsset].valley = 0;
            // transfer tokens
            tokens[_owner] += powers[msg.sender][_seq%numAsset].pre_valley_value;
            powers[msg.sender][_seq%numAsset].pre_valley_value = 0;
           SubmitPower(_power, _type);
           return true;
        } else if (3 == _type &&  _power - initialMeter[msg.sender].flat  >= powers[msg.sender][_seq%numAsset].flat ){
            initialMeter[msg.sender].flat += powers[msg.sender][_seq%numAsset].flat;
            powers[msg.sender][_seq%numAsset].flat = 0;
            // transfer tokens
            tokens[_owner] += powers[msg.sender][_seq%numAsset].pre_flat_value;
            powers[msg.sender][_seq%numAsset].pre_flat_value = 0;
            SubmitPower(_power, _type);
           return true;
        }else {
            SubmitPower(0, 0);
            return false;
        }
        
    }
    
    // name: withdrawToken
    // function: The seller withdraw his token asset from stellar to the smart contract to record in ethereum
    // input: 1. _value, uint256, amount of the token asset.
    //        2. _type, uint256, the type of the electricity.
    //        3. _meter, the meter's address.
    //        4. _seqMeter, uint256, the sequence of a meter.
    //        5. _seq, the sequence of selling the electricity.
    //        6. _owner, address, the owner of a meter.
    // return: bool, only for debug. 
    
    function withdrawToken(uint256 _value, uint256 _type,  address _meter, uint256 _seqMeter, uint256 _seq, address _owner) onlymanyowners(sha3(msg.data)) returns (bool) {
        if(!isMeter[_meter]) {
            throw;
        }
        if(ownMeters[_owner][_seqMeter] != _meter) {
            throw;
        }
        // tokens[_meter] = _value;
        if (1 == _type) {
           powers[_meter][_seq%numAsset].pre_peak_value += _value;
        } else if (2 == _type) {
           powers[_meter][_seq%numAsset].pre_valley_value += _value;
        } else if (3 == _type) {
           powers[_meter][_seq%numAsset].pre_flat_value += _value;
        }
        
        WithdrawToken(_value, _meter);
        return true;
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
        SetInitialMeter(_peak, _valley, _flat);
        return true;
    }

    // name: presale
    // function: record the the electricity declared on the stellar by the sellers
    // input:    1. _electricity, uint256, amount of the electricity sort of _type
    //           2. _type, uint256, the type of the electricity
    //           3. _meter, address, the address of a meter
    //           4. _seq, uint256, the sequence of selling the power on the stellar
    //           5. _seqMeter, uint256, the sequence of the meters owned by a seller
    //           6. _owner, address, the address of the owner of the meter
    
    function presale(uint256 _electricity, uint256 _type, address _meter, uint256 _seq, uint256 _seqMeter, address _owner) onlymanyowners(sha3(msg.data)) returns (bool) {
        if(!isMeter[_meter]) {
            throw;
        }
        
        if (ownMeters[_owner][_seqMeter] != _meter) {
            throw;
        }
        
        if (1== _type  ) {
            powers[_meter][_seq%numAsset].peak = _electricity;
            Presale(_electricity,_type, _meter);
            return true;
        } else if ( 2== _type ) {
            powers[_meter][_seq%numAsset].valley = _electricity;
            Presale(_electricity,_type, _meter);
            return true;
        } else if ( 3== _type ) {
            powers[_meter][_seq%numAsset].flat = _electricity;
            Presale(_electricity,_type, _meter);
            return true;
        } else {
            Presale(0, 0, _meter);
            return false;
        }
        
    }
    
}