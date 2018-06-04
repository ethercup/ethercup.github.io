pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './oraclizeAPI_0.4.sol';

contract BetTemplate is usingOraclize, Ownable {
  using SafeMath for uint;

  enum Status { Cancelled, Active }
  enum Winner { Undecided, P1, P2, Draw }

  uint private constant FEE_PERCENT = 1;
  uint private constant MIN_BET = 1e15;
  uint private constant DURATION_BETTING = 7 days;
  uint private constant DURATION_FETCHCONFIRM = 2 days;
  uint private constant DURATION_PAYOUT = 6 weeks;

  Status public status = Status.Active;

  uint public matchId;
  string public apiMatchId;
  string public matchContext;
  string public p1;
  string public p2;
  bool public isGroupPhase;
  uint public timeBettingOpens;
  uint public timeBettingCloses;
  uint public timeMatchEnds;
  uint public timeFetchStarts;
  uint public timeFetchConfirmEnds;
  uint public timeClaimsExpire;

  event FetchingFailed(uint balance, uint fetchAttempt, uint MAX_FETCH_ATTEMPTS);
  event WinnerFetched(Winner winner);
  event WinnerConfirmed(Winner winner);
  event BettingCancelled(string p1, string p2);

  uint private GAS_PRICE = 6e9; // 8GWei. Not constant so that it can be increased by the owner in case of higher demands in the future
  //uint private constant GAS_LIMIT = 300000; // works: 300000
  uint private constant GAS_LIMIT_MATCHSTATUS = 350000; // works: 300000
  uint private constant GAS_LIMIT_GOALS = 300000; // works: 300000
  uint private constant GAS_LIMIT_GOALS_PENALTY = 100000; // works: 300000
  uint private constant MAX_GAS = GAS_LIMIT_GOALS;
  
  uint private constant NORMAL_MAX_FETCHES = 5; // == 1x match result, 2x normal goals, 2x penalty shootout goals
  uint private constant MAX_FETCH_ATTEMPTS = 9;
  uint private constant FETCH_INTERVAL = 60*60;
  string private URL;
  uint public fetchFund;
  uint public fetchAttempt;
  bool public isFetchingStarted = false;
  bool public matchFinished = false;
  bytes32 private hashFinished;

  bytes32 public queryStatus;
  bytes32 public queryGoalsP1;
  bytes32 public queryGoalsP2;
  uint public goalsP1;
  uint public goalsP2;
  bool public goalsP1Fetched = false;
  bool public goalsP2Fetched = false;
  bool public fetchingPenaltyGoals = false;
  bool public winnerFetched = false;
  bool public winnerConfirmed = false;
  bool public ownerCalledConfirmFunction = false;
  Winner public winner; // default: 0 => Undefined

  string public test;

  uint public pool;
  uint public payoutPool;
  uint public remainingPayoutPool;
  uint public feeEarning;
  mapping(address => uint) public betsP1;
  mapping(address => uint) public betsP2;
  uint public total;
  uint public totalP1;
  uint public totalP2;
  uint public numBetsP1;
  uint public numBetsP2;

  bool public isInitialized;

  modifier onlyInitOnce() {
    require(isInitialized == false);
    isInitialized = true;
    _;
  }

  modifier hasMinWei() {
      require(msg.value >= MIN_BET);
      _;
  }

  /*
    Time-based modifiers
  */
  modifier isBettingPhase() {
      require(now >= timeBettingOpens && now < timeBettingCloses, 'It is too early or too late to bet.');
      _;
  }

  modifier canStartFetch() {
      require(now > timeFetchStarts);
      _;
  }

  modifier isExpiredPhase() {
      require(now > timeClaimsExpire);
      _;
  }

  modifier isClaimNotExpired() {
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

  modifier cancelIfTooLateForConfirmation() {
      if (now > timeFetchConfirmEnds && winnerConfirmed == false) {
        cancelInternal();
        // In case the modifier is called from a payable function, a cancel 
        // would result in lost funds. In case msg.sender sent funds, he'll
        // be reimbursed.
        if (msg.value > 0) {
          msg.sender.transfer(msg.value);
        }
      } else {
        _;
      }
  }

  /*
    Winner check modifiers
  */
  modifier isWinnerFetched() {
      require(winnerFetched == true);
      _;
  }

  modifier isNotWinnerFetched() {
      require(winnerFetched == false);
      _;
  }

  modifier isWinnerConfirmed() {
      require(winnerFetched == true && winnerConfirmed == true);
      _;
  }

  modifier isFirstConfirmCall() {
      require(ownerCalledConfirmFunction == false);
      _;
  }

  /*
    Other modifiers
  */
  modifier onlyOraclize() {
      require(msg.sender == oraclize_cbAddress());
      _;
  }

  modifier hasBetsOnWinner() {
      require(
        (winner == Winner.P1 && betsP1[msg.sender] > 0) ||
        (winner == Winner.P2 && betsP2[msg.sender] > 0) ||
        (winner == Winner.Draw && ((betsP1[msg.sender] > 0) || (betsP2[msg.sender] > 0)))
      );
      _;
  }

  modifier hasBets() {
      require(betsP1[msg.sender] > 0 || betsP2[msg.sender] > 0);
      _;
  }

  modifier startFetchingIfUnstarted() {
      if (isFetchingStarted == false) {
          fetchMatchStatus(0);
          isFetchingStarted = true;
      } else {
          _;
      }
  }

  modifier enoughFetchFund() {
      require(msg.value >= (NORMAL_MAX_FETCHES * oraclize_getPrice("URL", MAX_GAS)));
      _;
  }

  /*
    Helper functions
  */

  function isValidWinner(uint _winner)
      private
      view
      returns (bool)
  {
      if (_winner == 1 ||  _winner == 2) {
          return true;
      }
      if (isGroupPhase == true && _winner == 3) {
          return true;
      }
      return false;
  }

  function isFinished(string s)
      private
      view
      returns (bool)
  {
      return keccak256(s) == hashFinished;
  }

  constructor()
      public
  {
      oraclize_setCustomGasPrice(GAS_PRICE);
      hashFinished = keccak256('FINISHED');
  }

  function initBet(
      uint _matchId,
      string _apiMatchId,
      string _matchContext,
      string _p1,
      string _p2,
      bool _isGroupPhase,
      uint _matchStart)
      public
      payable
      //onlyOwner
      onlyInitOnce
  {
      fetchFund = msg.value;
      matchId = _matchId;
      apiMatchId = _apiMatchId;
      matchContext = _matchContext;
      p1 = _p1;
      p2 = _p2;
      isGroupPhase = _isGroupPhase;
      
      URL = strConcat('http://api.football-data.org/v1/fixtures/', apiMatchId);
      _setTimes(_matchStart);
  }

  function _setTimes(uint _matchStart)
      private
  {
      // Miners can cheat on block timestamp with a tolerance of 900 seconds.
      // That's why betting is closed 900 seconds before match start.
      timeBettingCloses = _matchStart - 15 minutes;
      timeBettingOpens = _matchStart - DURATION_BETTING;
      timeMatchEnds = timeBettingCloses + 105 minutes;
      timeFetchStarts = timeMatchEnds + 30 minutes;
      timeFetchConfirmEnds = _matchStart + DURATION_FETCHCONFIRM;
      timeClaimsExpire = _matchStart + DURATION_PAYOUT;
  }

  function betOnPlayer1()
      external
      payable
      isNotCancelled
      isBettingPhase
      hasMinWei
  {
      betsP1[msg.sender] = betsP1[msg.sender].add(msg.value);
      numBetsP1 = numBetsP1.add(1);
      totalP1 = totalP1.add(msg.value);
  }

  function betOnPlayer22()
      external
      payable
      isNotCancelled
      isBettingPhase
      hasMinWei
  {
      betsP2[msg.sender] = betsP2[msg.sender].add(msg.value);
      numBetsP2 = numBetsP2.add(1);
      totalP2 = totalP2.add(msg.value);
  }

  function fetchMatchStatus(uint _delay)
      private
  {
      string memory query = strConcat('json(', URL, ').fixture.status');
      queryStatus = fetch(query, _delay, GAS_LIMIT_MATCHSTATUS);
  }

  function fetchGoalsP1(uint _delay, bool _isPenalty)
      private
  {
      string memory query;

      if (_isPenalty == true) {
        query = strConcat('json(', URL, ').fixture.result.penaltyShootout.goalsHomeTeam');
        queryGoalsP1 = fetch(query, _delay, GAS_LIMIT_GOALS_PENALTY);
      } else {
        query = strConcat('json(', URL, ').fixture.result.goalsHomeTeam');
        queryGoalsP1 = fetch(query, _delay, GAS_LIMIT_GOALS);
      }
  }

  function fetchGoalsP2(uint _delay, bool _isPenalty)
      private
  {
      string memory query;

      if (_isPenalty == true) {
        query = strConcat('json(', URL, ').fixture.result.penaltyShootout.goalsAwayTeam');
        queryGoalsP2 = fetch(query, _delay, GAS_LIMIT_GOALS_PENALTY);
      } else {
        query = strConcat('json(', URL, ').fixture.result.goalsAwayTeam');
        queryGoalsP2 = fetch(query, _delay, GAS_LIMIT_GOALS);
      }
  }

  function fetch(string _query, uint _delay, uint _gaslimit)
      private
      returns (bytes32)
  {
      uint fetchCost = oraclize_getPrice("URL", _gaslimit);
      if (fetchFund >= fetchCost && fetchAttempt < MAX_FETCH_ATTEMPTS) {
          fetchAttempt = fetchAttempt.add(1);
          fetchFund = fetchFund.sub(fetchCost);
          return oraclize_query(_delay, 'URL', _query, _gaslimit);  
      } else {
          emit FetchingFailed(fetchFund, fetchAttempt, MAX_FETCH_ATTEMPTS);
          return 0x0;
      }
  }

  function __callback(bytes32 myid, string response)
      public
      onlyOraclize
      isNotWinnerFetched
  {
      // Keeping track of query IDs because one query can result in more than one callback.
      // Once callback received, query tracker set to 0 to prevent double handling of response.
      // See https://docs.oraclize.it/#ethereum-best-practices-mapping-query-ids
      if (myid == queryStatus && matchFinished == false) {
          _handleMatchStatusResponse(response);
      } else if (myid == queryGoalsP1) {
          _handleGoalsP1Response(response);
      } else if (myid == queryGoalsP2) {
          _handleGoalsP2Response(response);
      }
  }

  function _handleMatchStatusResponse(string response)
      private
  {
      if (isFinished(response)) {
          matchFinished = true;

          fetchGoalsP1(0, false);
          fetchGoalsP2(0, false);
      } else {
          fetchMatchStatus(FETCH_INTERVAL);
      }
  }

  function _handleGoalsP1Response(string strGoals)
      private
  {
      bytes memory byteGoals = bytes(strGoals);

      if(byteGoals.length == 0) {
          fetchGoalsP1(FETCH_INTERVAL, fetchingPenaltyGoals);
      } else {
          goalsP1 = parseInt(strGoals);
          goalsP1Fetched = true;

          if (goalsP2Fetched == true) {
              _suggestWinner(goalsP1, goalsP2);
          }
      }
  }

  function _handleGoalsP2Response(string strGoals)
      private
  {
      bytes memory byteGoals = bytes(strGoals);

      if(byteGoals.length == 0) {
          fetchGoalsP2(FETCH_INTERVAL, fetchingPenaltyGoals);
      } else {
          goalsP2 = parseInt(strGoals);
          goalsP2Fetched = true;

          if (goalsP1Fetched == true) {
              _suggestWinner(goalsP1, goalsP2);
          }
      }
  }

  function _suggestWinner(uint _goalsP1, uint _goalsP2)
      private
  {
      if (_goalsP1 > _goalsP2) {
          winner = Winner.P1;
          winnerFetched = true;
          emit WinnerFetched(winner);
      } else if (_goalsP1 < _goalsP2) {
          winner = Winner.P2;
          winnerFetched = true;
          emit WinnerFetched(winner);
      } else {
          // If we reach here, both teams have same amount of goals
          if (isGroupPhase == true) {
              winner = Winner.Draw;
              winnerFetched = true;
              emit WinnerFetched(winner);
          } else {
              // If this is reached match is knockout-match, meaning no draw is possible
              // --> Fetch penalty shootout goals
              // If still P1 and P2 have same amount of goals (shouldn't happen), MAX_FETCH_ATTEMPTS eventually cancels the bet
              fetchingPenaltyGoals = true;
              goalsP1Fetched = false;
              goalsP2Fetched = false;
              fetchGoalsP1(0, true);
              fetchGoalsP2(0, true);
          }
      }
  }

  function confirmWinner(uint _winnerAsInt)
      external
      onlyOwner
      isNotCancelled
      isWinnerFetched
      cancelIfTooLateForConfirmation
      isFirstConfirmCall // alternative modifier: canBeCancelled
  {
      require(isValidWinner(_winnerAsInt));
      ownerCalledConfirmFunction = true;

      if (winner == Winner(_winnerAsInt)) {
          winnerConfirmed = true;

          pool = totalP1.add(totalP2);

          if (pool > 0) {
              uint feeAmount = pool.mul(FEE_PERCENT).div(100);
              feeEarning = feeAmount;
              payoutPool = pool.sub(feeAmount);
              remainingPayoutPool = payoutPool;
              owner.transfer(feeAmount);
          } else {
              payoutPool = 0;
          }

          emit WinnerConfirmed(winner);
      } else {
          cancelInternal();
      }
  }

  function cancel()
      public
      onlyOwner
  {
      cancelInternal();
  }

  function cancelInternal()
      private
      isNotCancelled
      canBeCancelled
  {
      status = Status.Cancelled;
      payoutPool = totalP1.add(totalP2);
      remainingPayoutPool = payoutPool;

      emit BettingCancelled(p1, p2);
  }

  function updateStatus()
      external
      isNotCancelled
      canBeCancelled
  {
      if (now > timeFetchConfirmEnds && winnerConfirmed == false) {
        cancelInternal();
      }
  }

  function claimWinOrDraw()
      external
      isNotCancelled
      canStartFetch
      cancelIfTooLateForConfirmation
      startFetchingIfUnstarted
      isWinnerConfirmed
      isClaimNotExpired
  {
      uint payout;
      // Check if msg.sender has bets on winner team
      if (winner == Winner.P1 && betsP1[msg.sender] > 0) {
          payout = payoutPool.mul(betsP1[msg.sender]).div(totalP1);
          betsP1[msg.sender] = 0;
      } else if (winner == Winner.P2 && betsP2[msg.sender] > 0) {
          payout = payoutPool.mul(betsP2[msg.sender]).div(totalP2);
          betsP2[msg.sender] = 0;
      } else if (winner == Winner.Draw &&
          (betsP1[msg.sender] > 0 || betsP2[msg.sender] > 0))
      {
          payout = betsP1[msg.sender].add(betsP2[msg.sender]).mul(100-FEE_PERCENT).div(100);
          betsP1[msg.sender] = 0;
          betsP2[msg.sender] = 0;
      } else {
          revert();
      }

      require(remainingPayoutPool >= payout);
      remainingPayoutPool = remainingPayoutPool.sub(payout);

      msg.sender.transfer(payout);
  }

  function claimRefund()
      external
      isCancelled
      isClaimNotExpired
      hasBets
  {
      uint refund = betsP1[msg.sender].add(betsP2[msg.sender]);
      betsP1[msg.sender] = 0;
      betsP2[msg.sender] = 0;

      require(remainingPayoutPool >= refund);
      remainingPayoutPool = remainingPayoutPool.sub(refund);
      
      msg.sender.transfer(refund);
  }

  function claimExpired()
      external
      onlyOwner
      isExpiredPhase
  {
      payoutPool = 0;
      fetchFund = 0;

      msg.sender.transfer(address(this).balance);
  }

  function fundFetching()
      public
      payable
      isNotCancelled
      isNotWinnerFetched
      cancelIfTooLateForConfirmation
      enoughFetchFund
  {
      fetchFund = fetchFund.add(msg.value);
      fetchAttempt = 0;
      isFetchingStarted = true;
      fetchMatchStatus(0);
  }

  function fundingNeeded()
      public
      view 
      returns (uint)
  {
      uint costPerFetch = oraclize_getPrice("URL", MAX_GAS).mul(11).div(10);
      require(fetchFund < costPerFetch);

      return NORMAL_MAX_FETCHES * costPerFetch;
  }

  function increaseGasPriceBy(uint _extra)
      external
      onlyOwner
  {
      GAS_PRICE = GAS_PRICE.add(_extra);
  }

  function ()
      external
      payable
  {
      revert(); 
  }
}
