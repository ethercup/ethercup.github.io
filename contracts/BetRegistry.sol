pragma solidity ^0.4.23;

import './Bet.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract BetManager is Ownable {


    struct Bet {
        uint256 timeMatchStart,
        address betContract,
        string p1,
        string p2,
    }



    
    constructor() {

    }


    function registerBet() external {
        
    }