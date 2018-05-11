pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './oraclizeAPI_0.5.sol';

contract Bet is usingOraclize, Ownable {
  using SafeMath for uint256;

  enum Status { Active, Cancelled }
  enum Winner { Undecided, Player1, Player2, Draw }

  uint8 private constant FEE_PERCENT = 1;
  uint256 private constant CLAIM_EXPIRES_AFTER = 8 weeks;
  uint8 private constant MAX_GOALS = 25;

  Status public status = Status.Active;

  string public gameId;
  string public p1;
  string public p2;
  bool public isGroupPhase;
  uint256 public timeBettingOpens;
  uint256 public timeBettingCloses;
  uint256 public timeMatchEnds;
  uint256 public timeSuggestConfirmEnds;
  uint256 public timeClaimsExpire;

  event FetchMaxAttemptReached(string lastResult, uint256 MAX_FETCH_ATTEMPTS);
  event WinnerSuggested(Winner winner);
  event WinnerConfirmed(Winner winner);
  event BettingCancelled(string p1, string p2);

  uint256 private constant MAX_GAS_PRICE = 8e9;
  uint256 private constant MAX_FETCH_ATTEMPTS = 100;
  uint256 private constant FETCH_INTERVAL = 60*5; // 5min in seconds
  uint256 private fetchAttempt = 1;
  bool private isFetchingStarted = false;
  bool public matchFinished = false;
  bytes32 private hashFinished;

  bytes32 private queryStatus;
  bytes32 private queryGoalsP1;
  bytes32 private queryGoalsP2;
  uint private goalsP1;
  uint private goalsP2;
  bool private goalsP1Fetched = false;
  bool private goalsP2Fetched = false;
  bool private winnerSuggested = false;
  bool private winnerConfirmed = false;
  Winner public winner; // default = 0, meaning Undecided

  uint256 public pool;
  uint256 public payoutPool;
  mapping(address => uint256) public betsPlayer1;
  mapping(address => uint256) public betsPlayer2;
  uint256 public total;
  uint256 public totalPlayer1;
  uint256 public totalPlayer2;
  uint256 public numBetsPlayer1;
  uint256 public numBetsPlayer2;

  modifier hasWei() {
      require(msg.value > 0);
      _;
  }

  /*
    Time-based modifiers
  */
  modifier isBettingPhase() {
      require(now >= timeBettingOpens && now < timeBettingCloses, 'It is too early or too late to bet.');
      _;
  }

  modifier isSuggestConfirmPhase() {
      require(now > timeMatchEnds && now <= timeSuggestConfirmEnds, 'It is too early or too late to suggest/confirm a winner');
      _;
  }

  modifier isExpiredPhase() {
      require(now > timeClaimsExpire);
      _;
  }

  modifier isNotExpiredPhase() {
      require(now < timeClaimsExpire);
      _;
  }

  /*
    Cancelled modifiers
  */
  modifier isCancelled() {
      require(status == Status.Cancelled);
      _;
  }

  modifier isNotCancelled() {
      require(status == Status.Active);
      _;
  }

  modifier canBeCancelled() {
      require(winnerConfirmed == false, 'Cannot be cancelled because winner is already confirmed');
      _;
  }

  /*
    Winner check modifiers
  */
  modifier isWinnerSuggested() {
      require(winnerSuggested == true);
      _;
  }

  modifier isNotWinnerSuggested() {
      require(winnerSuggested == false);
      _;
  }

  modifier isWinnerConfirmed() {
      require(winnerSuggested == true && winnerConfirmed == true);
      _;
  }

  /*
    Other modifiers
  */
  modifier hasClaims() {
      require(
        (winner == Winner.Player1 && betsPlayer1[msg.sender] > 0) ||
        (winner == Winner.Player2 && betsPlayer2[msg.sender] > 0) ||
        (winner == Winner.Draw && ((betsPlayer1[msg.sender] > 0) || (betsPlayer2[msg.sender] > 0)))
      );
      _;
  }

  modifier startFetchingIfUnstarted() {
      if (isFetchingStarted == false) {
          fetchMatchStatus(0); // 0 == fetch now, without delay
          isFetchingStarted = true;
      }
      _;
  }



  /*
    Non-state-changing functions ("view" functions)
  */
  function hasBets(address _address) internal view returns (bool) {
      if (betsPlayer1[_address] > 0 || betsPlayer2[_address] > 0) {
          return true;
      }
      return false;
  }

  function isValidWinner(uint8 _winner) internal view returns (bool) {
      if (_winner == 1 ||  _winner == 2) {
          return true;
      }
      if (isGroupPhase == true && _winner == 3) {
          return true;
      }
      return false;
  }

  function isFinished(string s) private view returns (bool) {
      return keccak256(s) == hashFinished;
  }

  constructor(
      string _gameId,
      string _group,
      string _p1,
      string _p2,
      bool _isGroupPhase,
      uint256 _matchStart,
      uint256 _durationBetting,
      uint256 _durationSuggestConfirm)
      public
      payable
  {
      oraclize_setCustomGasPrice(MAX_GAS_PRICE);
      hashFinished = keccak256('FINISHED');
      
      gameId = _gameId;
      group = _group;
      p1 = _p1;
      p2 = _p2;
      isGroupPhase = _isGroupPhase;
      _setTimes(_matchStart, _durationBetting, _durationSuggestConfirm);
  }

  // public for testing
  function _setTimes(uint256 _matchStart, uint256 _durationBetting, uint256 _durationSuggestConfirm) public {
      require(_durationSuggestConfirm > 3600*2); // longer than 2h in case max match duration is reached (overtimes + penalty shootout)

      // Miners can cheat on block timestamp with a tolerance of 900 seconds.
      // That's why betting is closed 900 seconds before match start.
      timeBettingCloses = _matchStart - 900 seconds;
      timeBettingOpens = timeBettingCloses - _durationBetting;
      timeMatchEnds = timeBettingCloses + 105 minutes;
      timeSuggestConfirmEnds = timeMatchEnds + _durationSuggestConfirm;
      timeClaimsExpire = timeSuggestConfirmEnds + 8 weeks;
  }

  /* OLD BET FUNCTION: gas: 93620,  93627, 94136 */
  /* OLD BET FUNCTION: KOVAN: 54857 */
  function betOnPlayer1() external payable
      isNotCancelled
      isBettingPhase
      hasWei
  {
      betsPlayer1[msg.sender] = betsPlayer1[msg.sender].add(msg.value);
      numBetsPlayer1 += 1;
      totalPlayer1 = totalPlayer1.add(msg.value);
  }

  function betOnPlayer2() external payable
      isNotCancelled
      isBettingPhase
      hasWei
  {
      betsPlayer2[msg.sender] = betsPlayer2[msg.sender].add(msg.value);
      numBetsPlayer2 += 1;
      totalPlayer2 = totalPlayer2.add(msg.value);
  }


  function fetchMatchStatus(uint256 _delay) internal {
      string memory query = strConcat('json(http://api.football-data.org/v1/fixtures/', gameId, '.fixture');
      queryStatus = fetch(query, _delay);
  }

  function fetchGoalsP1(uint256 _delay) internal {
      string memory query = strConcat('json(http://api.football-data.org/v1/fixtures/', gameId, '.fixture.result.goalsHomeTeam');
      queryGoalsP1 = fetch(query, _delay);
  }

  function fetchGoalsP2(uint256 _delay) internal {
      string memory query = strConcat('json(http://api.football-data.org/v1/fixtures/', gameId, '.fixture.result.goalsAwayTeam');
      queryGoalsP2 = fetch(query, _delay);
  }

  function fetch(string _query, uint256 _delay) internal
      returns (bytes32)
  {
      return oraclize_query(_delay, "URL", _query);  
  }

  function __callback(bytes32 myid, string response) public
      isNotCancelled
      isSuggestConfirmPhase
      isNotWinnerSuggested
  {
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
      if (isFinished(response)) {
          matchFinished = true;

          fetchAttempt = fetchAttempt.add(2);
          fetchGoalsP1(0);
          fetchGoalsP2(0);
      } else if (fetchAttempt < (MAX_FETCH_ATTEMPTS-1)) {
          fetchAttempt = fetchAttempt.add(1);
          fetchMatchStatus(FETCH_INTERVAL);
      } else {
          status = Status.Cancelled;
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
              status = Status.Cancelled;
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
              status = Status.Cancelled;
              emit FetchMaxAttemptReached(strGoals, MAX_FETCH_ATTEMPTS);
          }
      }
      
      goalsP2 = goals;
      goalsP2Fetched = true;

      if (goalsP1Fetched == true) {
          _suggestWinner(goalsP1, goalsP2);
      }
  }

  function _suggestWinner(uint _goalsP1, uint _goalsP2) private {
      if (_goalsP1 > _goalsP2) {
          winner = Winner.Player1;
      } else if (_goalsP1 < _goalsP2) {
          winner = Winner.Player2;
      } else {
          winner = Winner.Draw;
      }

      winnerSuggested = true;
      emit WinnerSuggested(winner);
  }

  function confirmWinner(uint8 _winnerAsInt) external
      onlyOwner
      isNotCancelled
      isSuggestConfirmPhase
      isWinnerSuggested
  {
      require(isValidWinner(_winnerAsInt));
      
      if (winner == Winner(_winnerAsInt)) {
          winnerConfirmed = true;

          pool = totalPlayer1.add(totalPlayer2);

          if (pool > 0) {
              uint256 feeAmount = pool.mul(FEE_PERCENT).div(100);
              payoutPool = pool.sub(feeAmount);
              owner.transfer(feeAmount);
          } else {
              payoutPool = 0;
          }

          emit WinnerConfirmed(winner);
      } else {
          cancel();
      }
  }

  function cancel() public
      onlyOwner
      canBeCancelled
      isNotCancelled
  {
      status = Status.Cancelled;
      payoutPool = totalPlayer1.add(totalPlayer2);

      emit BettingCancelled(p1, p2);
  }

  function claimWinOrDraw() external
      isNotCancelled
      isNotExpiredPhase
      startFetchingIfUnstarted
      isWinnerConfirmed
      hasClaims
  {
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

  function claimCancelled() external
      isCancelled
      isNotExpiredPhase
      hasClaims
  {
      uint256 claim = betsPlayer1[msg.sender] + betsPlayer2[msg.sender]; // claim > 0 since check in hasClaims

      betsPlayer1[msg.sender] = 0;
      betsPlayer2[msg.sender] = 0;
      payoutPool = payoutPool.sub(claim);
      
      msg.sender.transfer(claim);
  }

  function claimExpired() external
      onlyOwner
      isExpiredPhase
  {
      payoutPool = 0;

      msg.sender.transfer(address(this).balance);
  }

  /* fallback function */
  function () public payable {
      revert('Function not found.'); 
  }

  // for testing
  // function suggestWinner(uint8 _winnerAsInt) external onlyOwner withinSuggestConfirmWinnerTime {
  //     require(isValidWinner(_winnerAsInt));
  //     suggestedWinner = Winner(_winnerAsInt);

  //     phase = Phase.WinnerSuggested;
  // }
}
