pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './oraclizeAPI_0.5.sol';

contract Bet is usingOraclize, Ownable {
  using SafeMath for uint256;

  enum Phase { Inactive, BettingOpen, BettingClosed, BettingWinnerSuggested, BettingDecided, BettingCancelled, BettingDecidedExpired }
  enum Winner { Player1, Player2, Draw }


  string public p1;
  string public p2;
  Phase public phase = Phase.Inactive;
  uint8 private constant FEE_PERCENT = 1;
  uint256 private constant CLAIM_EXPIRES_AFTER = 8 weeks;
  bool public drawAllowed;
  uint256 public timeBettingOpens;
  uint256 public timeBettingCloses;
  uint256 public timeMatchEnds;
  uint256 public timeSuggestConfirmEnds;
  uint256 public timeClaimsExpire;

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
  uint256 public FEE_PERCENTEarning;
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

  modifier withinSuggestConfirmWinnerTime() {
      require(phase != Phase.BettingCancelled && phase != Phase.BettingDecided);
      require(now > timeMatchEnds && now <= timeSuggestConfirmEnds);
      _;
  }

  modifier withinBettingPhase() {
      if (phase == Phase.Inactive && now >= timeBettingOpens && now < timeBettingCloses) {
          phase = Phase.BettingOpen;
          emit BettingOpen(p1, p2, timeBettingCloses);
      } else if ((phase == Phase.BettingOpen || phase == Phase.Inactive) && now >= timeBettingCloses) {
          phase = Phase.BettingClosed;
          emit BettingClosed(p1, p2);
      }
      _;
  }

  modifier withinClaimNotExpired() {
      require(phase == Phase.BettingCancelled || phase == Phase.BettingDecided);
      require(now < timeClaimsExpire);
      _;
  }

  modifier afterClaimsExpired() {
      require(now > timeClaimsExpire);
      _;
  }

  modifier eventuallyStartFetch() {
      if (fetchingStarted == false && phase != Phase.BettingDecided && phase != Phase.BettingCancelled) {
          fetchMatchResult(0); // 0 == fetch now, without delay
          fetchingStarted = true;
      }
      _;
  }

  modifier hasBetsOnWinner() {
      require(
        (winner == Winner.Player1 && betsPlayer1[msg.sender] > 0) ||
        (winner == Winner.Player2 && betsPlayer2[msg.sender] > 0) ||
        (winner == Winner.Draw && ((betsPlayer1[msg.sender] > 0) || (betsPlayer2[msg.sender] > 0)))
      );
      _;
  }

  function hasBets(address _address) internal view returns (bool) {
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
      uint256 _durationSuggestConfirm)
      public
      payable
  {
      //uint256 valueGETPRICE = oraclize_getPrice("URL");
      //uint256 valueMSGSENDER = msg.value;
      //require((oraclize_getPrice("URL")) < msg.value); // is it msg.value or this.balance here? TODO: enable
      p1 = _p1;
      p2 = _p2;
      drawAllowed = _drawAllowed;
      _setTimes(_matchStart, _durationBetting, _durationSuggestConfirm);
  }

  function _setTimes(uint256 _matchStart, uint256 _durationBetting, uint256 _durationSuggestConfirm) public {
      // miners can cheat on block timestamp with a tolerance of 900 seconds.
      // That's why betting is closed 900 seconds before match start.
      timeBettingCloses = _matchStart - 900 seconds;
      timeBettingOpens = timeBettingCloses - _durationBetting;
      timeMatchEnds = timeBettingCloses + 105 minutes;
      timeSuggestConfirmEnds = timeMatchEnds + _durationSuggestConfirm;
      timeClaimsExpire = timeSuggestConfirmEnds + 8 weeks;
  }

  /* gas: 93620,  93627, 94136 */
  function bet(uint8 _player) payable withinBettingPhase isBettingOpen returns (bool) {
      require(_player == 0 || _player == 1);
      require(msg.value > 0);

      if (_player == 0) {
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

  // for testing
  function suggestWinner(Winner _winner) external onlyOwner withinSuggestConfirmWinnerTime {
      require(checkWinner(_winner));
      suggestedWinner = _winner;
      phase = Phase.BettingWinnerSuggested;
  }

  function confirmWinner(Winner _winner) external onlyOwner atPhase(Phase.BettingWinnerSuggested) withinSuggestConfirmWinnerTime {
      if (suggestedWinner == _winner && checkWinner(_winner)) {
          winner = _winner;
          phase = Phase.BettingDecided;

          pool = totalPlayer1.add(totalPlayer2);

          uint256 FEE_PERCENTAmount;
          if (pool > 0) {
              FEE_PERCENTAmount = pool.mul(FEE_PERCENT).div(100);
              FEE_PERCENTEarning = FEE_PERCENTAmount;
              payoutPool = pool.sub(FEE_PERCENTAmount);
              owner.transfer(FEE_PERCENTAmount);
          } else {
              FEE_PERCENTAmount = 0;
              payoutPool = 0;
          }

          emit BettingDecided(p1, p2, winner);
      } else {
          cancel();
      }
  }

  function _getWinnerFromString(string result) internal returns (Winner) {
      return Winner.Player1;
      // TODO: orallize has built in parseInt
  }

  function fetchMatchResult(uint256 _delay) internal {
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

  function cancel() public onlyOwner canBeCancelled {
      phase = Phase.BettingCancelled;
      payoutPool = totalPlayer1.add(totalPlayer2);

      emit BettingCancelled(p1, p2);
  }

  function claimWinOrDraw() external eventuallyStartFetch isDecided withinClaimNotExpired hasBetsOnWinner {
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

  function claimCancelled() external isCancelled withinClaimNotExpired {
      uint256 claim = betsPlayer1[msg.sender] + betsPlayer2[msg.sender];
      require(claim > 0);

      betsPlayer1[msg.sender] = 0;
      betsPlayer2[msg.sender] = 0;
      payoutPool = payoutPool.sub(claim);
      
      msg.sender.transfer(claim);
  }

  function claimExpired() external onlyOwner afterClaimsExpired {
      uint256 expired = payoutPool;
      payoutPool = 0;

      phase = Phase.BettingDecidedExpired;

      msg.sender.transfer(expired);
  }

  /* fallback function */
  function () public payable {
      revert(); 
  }
}
