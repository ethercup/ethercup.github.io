pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract BetRegistry is Ownable {

    mapping(uint256 => address) public betContracts;
    
    constructor() public {
    }

    function putBet(uint256 _matchStartTime, address _address) external
        onlyOwner
    {
        betContracts[_matchStartTime] = _address;
    }
}