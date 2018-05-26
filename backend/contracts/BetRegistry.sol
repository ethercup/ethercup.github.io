pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract BetRegistry is Ownable {

    uint8 public constant NUM_MATCHES = 64; // must be smaller than uint8.MAX_VALUE
    uint8 public nextIndex;
    address[NUM_MATCHES] public betContracts;
    
    constructor() public {
    }

    function replaceBet(uint8 _id, address _address) external
        onlyOwner
    {
        require(betContracts[_id] != address(0));
        require(_id < NUM_MATCHES);

        betContracts[_id] = _address;
    }

    function addBet(address _address) external
        onlyOwner
    {
        require(nextIndex < NUM_MATCHES);

        betContracts[nextIndex] = _address;
        nextIndex += 1;
    }

    /* fallback function */
    function () public payable {
      revert(); 
    }
}