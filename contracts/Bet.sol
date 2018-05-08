pragma solidity ^0.4.23;

import './zeppelin/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './oraclizeAPI_0.5.sol';

contract Bet is usingOraclize, Ownable {
  using SafeMath for uint256;

  enum Phase { Inactive, BettingOpen, BettingClosed, BettingWinnerSuggested, BettingConfirmed, BettingCancelled, BettingConfirmedExpired }
  enum Winner { Undecided, Player1, Player2, Draw }

  uint8 private constant FEE_PERCENT = 1;
  uint256 private constant CLAIM_EXPIRES_AFTER = 8 weeks;
  uint8 private constant MAX_GOALS = 25;

  Phase public phase = Phase.Inactive;

  string public gameId;
  string public p1;
  string public p2;
  bool public drawAllowed;
  uint256 public timeBettingOpens;
  uint256 public timeBettingCloses;
  uint256 public timeMatchEnds;
  uint256 public timeSuggestConfirmEnds;
  uint256 public timeClaimsExpire;

  event FetchStatusRequest();
  event FetchStatusResult(string result, uint256 fetchAttempt, uint256 MAX_FETCH_ATTEMPTS);
  event FetchStatusFinalResult(string result, uint256 fetchAttempt, uint256 MAX_FETCH_ATTEMPTS);
  event FetchMaxAttemptReached(string lastResult, uint256 MAX_FETCH_ATTEMPTS);

  event WinnerSuggested(string winner);

  event BettingOpen(string p1, string p2, uint timeBettingCloses);
  event BettingClosed(string p1, string p2);
  event BettingConfirmed(string p1, string p2, Winner winner);
  event BettingCancelled(string p1, string p2);

  bool private fetchingStarted = false;
  uint256 constant MAX_FETCH_ATTEMPTS = 100;
  uint256 constant FETCH_INTERVAL = 60*5; // 5min in seconds
  uint256 private fetchAttempt = 1;
  bool public matchFinished = false;

  bytes32 private queryStatus;
  bytes32 private queryGoalsP1;
  bytes32 private queryGoalsP2;
  uint private goalsP1;
  uint private goalsP2;
  bool private goalsP1Fetched = false;
  bool private goalsP2Fetched = false;
  Winner public suggestedWinner; // default = 0, meaning Undecided
  Winner public winner; // default = 0, meaning Undecided

  uint256 public pool;
  uint256 public payoutPool;
  uint256 public feeEarning;
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

  modifier isConfirmed() {
      require(phase == Phase.BettingConfirmed);
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
      require(phase != Phase.BettingCancelled && phase != Phase.BettingConfirmed);
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

  modifier stillFetching() {
      require(fetchingStarted == true);
      // Makes sure that phase != BettingWinnerSuggested and phase != BettingCancelled
      require(phase == Phase.BettingClosed); 
      _;
  }

  modifier withinClaimNotExpired() {
      require(phase == Phase.BettingCancelled || phase == Phase.BettingConfirmed);
      require(now < timeClaimsExpire);
      _;
  }

  modifier afterClaimsExpired() {
      require(now > timeClaimsExpire);
      _;
  }

  modifier eventuallyStartFetch() {
      if (
          fetchingStarted == false &&
          phase != Phase.BettingConfirmed && phase != Phase.BettingCancelled && 
          now > timeMatchEnds && now <= timeSuggestConfirmEnds
      ) {
          fetchMatchStatus(0); // 0 == fetch now, without delay
          fetchingStarted = true;
      }
      _;
  }

  modifier hasClaims() {
      require(
        (winner == Winner.Player1 && betsPlayer1[msg.sender] > 0) ||
        (winner == Winner.Player2 && betsPlayer2[msg.sender] > 0) ||
        ((winner == Winner.Draw || phase == Phase.BettingCancelled) && ((betsPlayer1[msg.sender] > 0) || (betsPlayer2[msg.sender] > 0)))
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
      string _gameId,
      string _p1,
      string _p2,
      bool _drawAllowed,
      uint256 _matchStart,
      uint256 _durationBetting,
      uint256 _durationSuggestConfirm)
      public
      payable
  {
      oraclize_setCustomGasPrice(8e9);   // 4Gwei: 4000000000
      //uint256 valueGETPRICE = oraclize_getPrice("URL");
      //uint256 valueMSGSENDER = msg.value;
      //require((oraclize_getPrice("URL")) < msg.value); // is it msg.value or this.balance here? TODO: enable
      gameId = _gameId;
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
  function bet(uint8 _player) public payable withinBettingPhase isBettingOpen returns (bool) {
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

  function fetchMatchStatus(uint256 _delay) internal {
      string memory query = strConcat('json(http://api.football-data.org/v1/fixtures/', gameId, '.fixture');
      queryStatus = oraclize_query(_delay, "URL", query);    
  }

  function fetchGoalsP1(uint256 _delay) internal {
      string memory query = strConcat('json(http://api.football-data.org/v1/fixtures/', gameId, '.fixture.result.goalsHomeTeam');
      queryGoalsP1 = oraclize_query(_delay, "URL", query);  
  }

  function fetchGoalsP2(uint256 _delay) internal {
      string memory query = strConcat('json(http://api.football-data.org/v1/fixtures/', gameId, '.fixture.result.goalsAwayTeam');
      queryGoalsP2 = oraclize_query(_delay, "URL", query);  
  }

  function __callback(bytes32 myid, string response) public stillFetching {
      require(msg.sender == oraclize_cbAddress());
      
      // Keeping track of query IDs because one query can result in more than one callback.
      // Once callback received, query tracker set to 0 to prevent double handling of response.
      // See https://docs.oraclize.it/#ethereum-best-practices-mapping-query-ids
      if (myid == queryStatus && matchFinished == false) {
          queryStatus = 0x0;
          _handleMatchStatusResponse(response);
      } else if (myid == queryGoalsP1) {
          queryGoalsP1 = 0x0;
          _handleGoalsP1Response(response);
      } else if (myid == queryGoalsP2) {
          queryGoalsP2 = 0x0;
          _handleGoalsP2Response(response);
      }
  }

  function _handleMatchStatusResponse(string response) private {
      if (areEqualStrings(response, 'FINISHED')) {
          matchFinished = true;
          emit FetchStatusFinalResult(response, fetchAttempt, MAX_FETCH_ATTEMPTS);

          fetchAttempt = fetchAttempt.add(2);
          fetchGoalsP1(0);
          fetchGoalsP2(0);
      } else if (fetchAttempt < (MAX_FETCH_ATTEMPTS-1)) {
          fetchAttempt = fetchAttempt.add(1);
          emit FetchStatusResult(response, fetchAttempt, MAX_FETCH_ATTEMPTS);
          fetchMatchStatus(FETCH_INTERVAL);
      } else {
          phase = Phase.BettingCancelled;
          emit FetchMaxAttemptReached(response, MAX_FETCH_ATTEMPTS);
      }
  }

  function _handleGoalsP1Response(string strGoals) private {
      uint goals = parseInt(strGoals);
      if (goals > MAX_GOALS) {
          fetchAttempt = fetchAttempt.add(1);
          if (fetchAttempt < MAX_FETCH_ATTEMPTS) {
              fetchGoalsP2(FETCH_INTERVAL);
          } else {
              phase = Phase.BettingCancelled;
              emit FetchMaxAttemptReached(strGoals, MAX_FETCH_ATTEMPTS);
          }
      }

      goalsP1 = goals;
      goalsP1Fetched = true;

      if (goalsP2Fetched == true) {
          _suggestWinner(goalsP1, goalsP2);
      }
  }

  function _handleGoalsP2Response(string strGoals) private {
      uint goals = parseInt(strGoals);
      if (goals > MAX_GOALS) {
          fetchAttempt = fetchAttempt.add(1);
          if (fetchAttempt < MAX_FETCH_ATTEMPTS) {
              fetchGoalsP2(FETCH_INTERVAL);
          } else {
              phase = Phase.BettingCancelled;
              emit FetchMaxAttemptReached(strGoals, MAX_FETCH_ATTEMPTS);
          }
      }
      
      goalsP2 = goals;
      goalsP2Fetched = true;

      if (goalsP1Fetched == true) {
          _suggestWinner(goalsP1, goalsP2);
      }
  }

  function _suggestWinner(uint _goalsP1, uint _goalsP2) private returns (Winner) {
      if (_goalsP1 > _goalsP2) {
          suggestedWinner = Winner.Player1;
          emit WinnerSuggested(p1);
      } else if (_goalsP1 < _goalsP2) {
          suggestedWinner = Winner.Player2;
          emit WinnerSuggested(p2);
      } else {
          suggestedWinner = Winner.Draw;
          emit WinnerSuggested('DRAW');
      }

      phase = Phase.BettingWinnerSuggested;

      return suggestedWinner;
  }

  function areEqualStrings(string a, string b) private pure returns (bool) {
       return keccak256(a) == keccak256(b);
  }

  // for testing
  function suggestWinner(uint8 _winnerAsInt) external onlyOwner withinSuggestConfirmWinnerTime {
      require(isValidWinner(_winnerAsInt));
      suggestedWinner = Winner(_winnerAsInt);

      phase = Phase.BettingWinnerSuggested;
  }

  function confirmWinner(uint8 _winnerAsInt) external onlyOwner atPhase(Phase.BettingWinnerSuggested) withinSuggestConfirmWinnerTime {
      require(isValidWinner(_winnerAsInt));
      Winner _winner = Winner(_winnerAsInt);

      if (suggestedWinner == _winner) {
          winner = _winner;
          phase = Phase.BettingConfirmed;

          pool = totalPlayer1.add(totalPlayer2);

          uint256 feeAmount;
          if (pool > 0) {
              feeAmount = pool.mul(FEE_PERCENT).div(100);
              feeEarning = feeAmount;
              payoutPool = pool.sub(feeAmount);
              owner.transfer(feeAmount);
          } else {
              feeAmount = 0;
              payoutPool = 0;
          }

          emit BettingConfirmed(p1, p2, winner);
      } else {
          cancel();
      }
  }

  function isValidWinner(uint8 _winner) internal view returns (bool) {
      if (_winner == 1 ||  _winner == 2) {
          return true;
      }
      if (drawAllowed == true && _winner == 3) {
          return true;
      }
      return false;
  }

  function cancel() public onlyOwner canBeCancelled {
      phase = Phase.BettingCancelled;
      payoutPool = totalPlayer1.add(totalPlayer2);

      emit BettingCancelled(p1, p2);
  }

  function claimWinOrDraw() external eventuallyStartFetch isConfirmed withinClaimNotExpired hasClaims {
      uint256 wonShare;
      uint256 payout;
      if (winner == Winner.Player1){
          wonShare = betsPlayer1[msg.sender].mul(1e20).div(totalPlayer1);//.div(1e20)
          payout = payoutPool.mul(wonShare).div(1e20);
          betsPlayer1[msg.sender] = 0;
      } else if (winner == Winner.Player2) {
          wonShare = betsPlayer2[msg.sender].mul(1e20).div(totalPlayer2);//.div(1e20)
          payout = payoutPool.mul(wonShare).div(1e20);
          betsPlayer2[msg.sender] = 0;
      } else if (winner == Winner.Draw) {
          payout = betsPlayer1[msg.sender] + betsPlayer2[msg.sender];
          betsPlayer1[msg.sender] = 0;
          betsPlayer2[msg.sender] = 0;
      }
      payoutPool = payoutPool.sub(payout);

      msg.sender.transfer(payout);
  }

  function claimCancelled() external isCancelled withinClaimNotExpired hasClaims {
      uint256 claim = betsPlayer1[msg.sender] + betsPlayer2[msg.sender]; // claim > 0 since check in hasClaims

      betsPlayer1[msg.sender] = 0;
      betsPlayer2[msg.sender] = 0;
      payoutPool = payoutPool.sub(claim);
      
      msg.sender.transfer(claim);
  }

  function claimExpired() external onlyOwner afterClaimsExpired {
      uint256 expired = payoutPool;
      payoutPool = 0;

      phase = Phase.BettingConfirmedExpired;

      msg.sender.transfer(expired);
  }

  /* fallback function */
  function () public payable {
      revert(); 
  }
}
