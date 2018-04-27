pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract Bet is Ownable {
  using SafeMath for uint256;

  enum Phase { Inactive, BettingOpen, BettingClosed, BettingDecided, Cancelled }
  enum Winner { Player1, Player2, Draw }


  string public player1;
  string public player2;
  Phase public phase = Phase.Inactive;
  uint8 public constant feePermille = 5;
  uint256 public constant timeClaimExpires = 8 weeks;
  bool public drawAllowed;
  uint256 public timeBettingOpens;
  uint256 public timeBettingCloses;

  event BettingOpen(string player1, string player2, uint timeBettingCloses);
  event BettingClosed(string player1, string player2);
  event BettingDecided(string player1, string player2, Winner winner);
  event BettingCancelled(string player1, string player2);

  Winner public winner;
  uint256 public pool;
  uint256 public payoutPool;
  mapping(address => uint256) public betsPlayer1;
  mapping(address => uint256) public betsPlayer2;
  uint256 public total;
  uint256 public totalPlayer1;
  uint256 public totalPlayer2;
  uint256 public numBetsPlayer1;
  uint256 public numBetsPlayer2;

  /* atPhase modifier or individual modifiers for every phase? */
  modifier atPhase(Phase _phase) {
    require(phase == _phase);
    _;
  }

  modifier isBettingOpen() {
    require(phase == Phase.BettingOpen);
    _;
  }

  modifier isBettingClosed() {
    require(phase == Phase.BettingOpen);
    _;
  }

  modifier isDecided() {
    require(phase == Phase.BettingDecided);
    _;
  }

  modifier isCancelled() {
    require(phase == Phase.Cancelled);
    _;
  }

  modifier canBeCancelled() {
    require(
        phase == Phase.Inactive ||
        phase == Phase.BettingOpen ||
        phase == Phase.BettingClosed
    );
    _;
  }

  modifier onlyAfter(uint256 _duration) {
    require(now >= timeBettingCloses + _duration);
    _;
  }

  modifier onlyBefore(uint256 _duration) {
    require(now < timeBettingCloses + _duration);
    _;
  }

  modifier checkBettingPhase() {
    if (phase == Phase.Inactive && now >= timeBettingOpens && now < timeBettingCloses) {
      phase = Phase.BettingOpen;
      emit BettingOpen(player1, player2, timeBettingCloses);
    } else if ((phase == Phase.BettingOpen || phase == Phase.Inactive) && now >= timeBettingCloses) {
      phase = Phase.BettingClosed;
      emit BettingClosed(player1, player2);
    }
    _;
  }

  function hasBets(address _address) internal view isDecided returns (bool) {
    if (betsPlayer1[_address] > 0 || betsPlayer2[_address] > 0) {
      return true;
    }
    return false;
  }

  constructor(
      string _player1,
      string _player2,
      bool _drawAllowed,
      uint256 _matchStart,
      uint256 _durationBetting) public {
    player1 = _player1;
    player2 = _player2;
    drawAllowed = _drawAllowed;
    // miners can cheat on block timestamp with a tolerance of 900 seconds.
    // That's why betting is closed 900 seconds before match start.
    timeBettingCloses = _matchStart - 900 seconds;
    timeBettingOpens = timeBettingCloses - _durationBetting;
  }

  /* gas: 93620,  93627, 94136 */
  function bet(uint8 _player) payable checkBettingPhase isBettingOpen returns (bool) {
    require(_player == 1 || _player == 2);
    require(msg.value > 0);

    if (_player == 1) {
      betsPlayer1[msg.sender] = betsPlayer1[msg.sender].add(msg.value);
      numBetsPlayer1 += 1;
      totalPlayer1 = totalPlayer1.add(msg.value);
    } else {
      betsPlayer2[msg.sender] = betsPlayer2[msg.sender].add(msg.value);
      numBetsPlayer2 += 1;
      totalPlayer2 = totalPlayer2.add(msg.value);
    }
    return true;
  }

  function checkWinner(Winner _winner) internal view returns (bool) {
    if (_winner == Winner.Player1 || _winner == Winner.Player2) {
      return true;
    }
    if (drawAllowed == true && _winner == Winner.Draw) {
      return true;
    }
    return false;
  }

  function decideWinner(Winner _winner) external onlyOwner isBettingClosed onlyAfter(90 minutes) {
    require(checkWinner(_winner));
    winner = _winner;

    pool = totalPlayer1.add(totalPlayer2);
    uint256 fee = pool.mul(feePermille).div(1000);
    payoutPool = pool.sub(fee);

    phase = Phase.BettingDecided;
    emit BettingDecided(player1, player2, winner);

    owner.transfer(fee);
  }

  function cancel() external onlyOwner canBeCancelled {
    phase = Phase.Cancelled;
    payoutPool = totalPlayer1.add(totalPlayer2);

    emit BettingCancelled(player1, player2);
  }

  function claimWinOrDraw() external isDecided onlyBefore(timeClaimExpires) {
    require(hasBets(msg.sender));
    require(checkWinner(winner)); // should be redundent

    uint256 wonShare;
    uint256 payout;
    if (winner == Winner.Player1 && betsPlayer1[msg.sender] > 0){
      wonShare = betsPlayer1[msg.sender].mul(1e20).div(totalPlayer1);//.div(1e20)
      payout = payoutPool.mul(wonShare).div(1e20);
      betsPlayer1[msg.sender] = 0;
    } else if (winner == Winner.Player2 && betsPlayer2[msg.sender] > 0) {
      wonShare = betsPlayer2[msg.sender].mul(1e20).div(totalPlayer2);//.div(1e20)
      payout = payoutPool.mul(wonShare).div(1e20);
      betsPlayer2[msg.sender] = 0;
    } else if (winner == Winner.Draw && hasBets(msg.sender)) {
      payout = betsPlayer1[msg.sender] + betsPlayer2[msg.sender];
      betsPlayer1[msg.sender] = 0;
      betsPlayer2[msg.sender] = 0;
    }
    payoutPool = payoutPool.sub(payout);

    msg.sender.transfer(payout);
  }

  function claimCancelled() external isCancelled onlyBefore(timeClaimExpires) {
    uint256 claim = betsPlayer1[msg.sender] + betsPlayer2[msg.sender];
    require(claim > 0);

    betsPlayer1[msg.sender] = 0;
    betsPlayer2[msg.sender] = 0;
    payoutPool = payoutPool.sub(claim);
    
    msg.sender.transfer(claim);
  }

  function claimExpired() external onlyOwner onlyAfter(timeClaimExpires) {
    uint256 expired = payoutPool;
    payoutPool = 0;

    msg.sender.transfer(expired);
  }

  function test() payable returns (bool) {
    uint256 amount = msg.value;
    return true;
  }

  /* fallback function */
  function () public payable {
    revert(); 
  }
}
