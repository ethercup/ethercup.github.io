pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './oraclizeAPI_0.5.sol';

contract Bet is usingOraclize, Ownable {
  using SafeMath for uint256;

  enum Phase { Inactive, BettingOpen, BettingClosed, BettingWinnerSuggested, BettingDecided, BettingCancelled }
  enum Winner { Player1, Player2, Draw }


  string public p1;
  string public p2;
  Phase public phase = Phase.Inactive;
  uint8 private constant FEE = 1;
  uint256 private constant CLAIM_EXPIRES_AFTER = 8 weeks;
  bool private drawAllowed;
  uint256 public timeBettingOpens;
  uint256 public timeBettingCloses;
  uint256 public durationConfirmation;

  event FetchRequest();
  event FetchResult(string result, uint256 fetchAttempt, uint256 maxFetchAttempts);
  event FetchFinalResult(string result, uint256 fetchAttempt, uint256 maxFetchAttempts);
  event FetchMaxAttemptReached(string lastResult, uint256 maxFetchAttempts);

  event BettingOpen(string p1, string p2, uint timeBettingCloses);
  event BettingClosed(string p1, string p2);
  event BettingDecided(string p1, string p2, Winner winner);
  event BettingCancelled(string p1, string p2);

  bool private fetchingStarted = false;
  uint256 private maxFetchAttempts = 300;
  uint256 private fetchInterval = 60; // in seconds
  uint256 private fetchAttempt = 0;
  bool private winnerFetched = false;
  Winner public suggestedWinner;
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
      require(phase == Phase.BettingCancelled);
      _;
  }

  modifier canBeCancelled() {
      require(
          phase == Phase.Inactive ||
          phase == Phase.BettingOpen ||
          phase == Phase.BettingClosed ||
          phase == Phase.BettingWinnerSuggested
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
          emit BettingOpen(p1, p2, timeBettingCloses);
      } else if ((phase == Phase.BettingOpen || phase == Phase.Inactive) && now >= timeBettingCloses) {
          phase = Phase.BettingClosed;
          emit BettingClosed(p1, p2);
      }
      _;
  }

  modifier checkFetchMatchResult() {
      if ((fetchingStarted == false) && (now >= timeBettingCloses + 120 minutes)) {
          fetchMatchResult(0); // 0 == fetch now, without delay
          fetchingStarted = true;
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
      string _p1,
      string _p2,
      bool _drawAllowed,
      uint256 _matchStart,
      uint256 _durationBetting,
      uint256 _durationConfirmation)
      public
      payable
  {
      //require((oraclize_getPrice("URL")) < msg.value); // is it msg.value or this.balance here? TODO: enable
      p1 = _p1;
      p2 = _p2;
      drawAllowed = _drawAllowed;
      // miners can cheat on block timestamp with a tolerance of 900 seconds.
      // That's why betting is closed 900 seconds before match start.
      timeBettingCloses = _matchStart - 900 seconds;
      timeBettingOpens = timeBettingCloses - _durationBetting;
      durationConfirmation = _durationConfirmation; // 120 ~= match duration
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

  function __callback(bytes32 myid, string result) {
        require(msg.sender == oraclize_cbAddress());

        bytes memory byteResult = bytes(result); 

        if (byteResult.length != 0) { // TODO: see real result
            suggestedWinner = _getWinnerFromString(result);
            phase = Phase.BettingWinnerSuggested;
            emit FetchFinalResult(result, fetchAttempt, maxFetchAttempts);
        } else if (fetchAttempt < maxFetchAttempts) {
            fetchAttempt = fetchAttempt.add(1);
            emit FetchResult(result, fetchAttempt, maxFetchAttempts);
            fetchMatchResult(fetchInterval);
        } else {
            phase = Phase.BettingCancelled;
            emit FetchMaxAttemptReached(result, maxFetchAttempts);
        }
  }

  function confirmWinner(Winner _winner) external onlyOwner onlyAfter(durationConfirmation) atPhase(Phase.BettingWinnerSuggested) {
      if (suggestedWinner == _winner && checkWinner(_winner)) {
          winner = _winner;

          pool = totalPlayer1.add(totalPlayer2);
          uint256 feeAmount = pool.mul(FEE).div(1000);
          payoutPool = pool.sub(feeAmount);

          phase = Phase.BettingDecided;
          emit BettingDecided(p1, p2, winner);

          owner.transfer(feeAmount);
      } else {
          cancel();
      }
  }

  function _getWinnerFromString(string result) internal returns (Winner) {
      return Winner.Player1;
      // TODO: orallize has built in parseInt
  }

  function fetchMatchResult(uint256 _delay) {
      oraclize_query(_delay, "URL", "json(https://WORLDCUP_URL).match.result");    
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

  // TODO: replace with suggestWinner (oraclize) and confirmWinner (onlyOwner)
  /*function decideWinner(Winner _winner) external onlyOwner isBettingClosed onlyAfter(90 minutes) {
      require(checkWinner(_winner));
      winner = _winner;

      pool = totalPlayer1.add(totalPlayer2);
      uint256 feeAmount = pool.mul(FEE).div(1000);
      payoutPool = pool.sub(feeAmount);

      phase = Phase.BettingDecided;
      emit BettingDecided(p1, p2, winner);

      owner.transfer(feeAmount);
  }*/

  function cancel() public onlyOwner canBeCancelled {
      phase = Phase.BettingCancelled;
      payoutPool = totalPlayer1.add(totalPlayer2);

      emit BettingCancelled(p1, p2);
  }

  function claimWinOrDraw() external checkFetchMatchResult isDecided onlyBefore(CLAIM_EXPIRES_AFTER) {
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

  function claimCancelled() external isCancelled onlyBefore(CLAIM_EXPIRES_AFTER) {
      uint256 claim = betsPlayer1[msg.sender] + betsPlayer2[msg.sender];
      require(claim > 0);

      betsPlayer1[msg.sender] = 0;
      betsPlayer2[msg.sender] = 0;
      payoutPool = payoutPool.sub(claim);
      
      msg.sender.transfer(claim);
  }

  function claimExpired() external onlyOwner onlyAfter(CLAIM_EXPIRES_AFTER) {
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
