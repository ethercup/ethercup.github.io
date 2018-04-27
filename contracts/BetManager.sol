pragma solidity ^0.4.23;

import './Bet.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract BetManager is Ownable {

	mapping(string => bool) players;
	address[] bets;

	constructor() public {
		initPlayers();
	}

	function createBet(
	  string _player1,
	  string _player2,
	  bool _drawAllowed,
	  uint256 _matchStart,
      uint256 _durationBetting) external onlyOwner returns (address){
      	require(areValidPlayers(_player1, _player2));
      	require(_matchStart > now);

      	address betContract = new Bet(_player1, _player2, _drawAllowed, _matchStart, _durationBetting);
      	bets.push(betContract);

      	return betContract;
	}

	function areValidPlayers(string p1, string p2) view internal returns (bool){
		return (players[p1] == true && players[p2] == true);
	}

	function initPlayers() private {
		players["Argentina"] = true;
		players["Australia"] = true;
		players["Belgium"] = true;
		players["Brazil"] = true;
		players["Colombia"] = true;
		players["Costa Rica"] = true;
		players["Croatia"] = true;
		players["Denmark"] = true;
		players["Egypt"] = true;
		players["England"] = true;
		players["France"] = true;
		players["Germany"] = true;
		players["Iceland"] = true;
		players["Iran"] = true;
		players["Japan"] = true;
		players["Mexico"] = true;
		players["Morocco"] = true;
		players["Nigeria"] = true;
		players["Panama"] = true;
		players["Peru"] = true;
		players["Poland"] = true;
		players["Portugal"] = true;
		players["Russia"] = true;
		players["Saudi Arabia"] = true;
		players["Senegal"] = true;
		players["Servia"] = true;
		players["South Korea"] = true;
		players["Spain"] = true;
		players["Sweden"] = true;
		players["Switzerland"] = true;
		players["Tunisia"] = true;
		players["Uruguay"] = true;
	}
}