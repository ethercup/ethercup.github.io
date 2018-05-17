pragma solidity ^0.4.23;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract BetRegistry is Ownable {

    uint8 private numMatches = 64;
    address[64] public betContracts;
    
    constructor() public {
    }

    function putBet(uint8 _id, address _address) external
        onlyOwner
    {
        betContracts[_id] = _address;
    }

    /* fallback function */
    function () public payable {
      revert(); 
    }
}