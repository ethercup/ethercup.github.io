pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract BetRegistry is Ownable {
    using SafeMath for uint;

    uint public constant NUM_MATCHES = 64; // must be smaller than uint8.MAX_VALUE
    uint public nextIndex;
    uint public numReplacedContracts;

    address[NUM_MATCHES] public betContracts;
    address[] public replacedBetContracts;
    
    constructor() public {
    }

    function replaceBet(uint _id, address _address) external
        onlyOwner
    {
        require(betContracts[_id] != address(0));
        require(_id < NUM_MATCHES);

        address replaced = betContracts[_id];
        replacedBetContracts.push(replaced);
        numReplacedContracts = numReplacedContracts.add(1);
        
        betContracts[_id] = _address;
    }

    function addBet(address _address) external
        onlyOwner
    {
        require(nextIndex < NUM_MATCHES);

        betContracts[nextIndex] = _address;
        nextIndex = nextIndex.add(1);
    }

    function getReplacedBet(uint _id) external view
        returns (address) 
    {
        require(_id < numReplacedContracts);

        return replacedBetContracts[_id];
    }

    /* fallback function */
    function () public payable {
      revert(); 
    }
}