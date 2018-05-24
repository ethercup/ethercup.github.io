pragma solidity ^0.4.23;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './oraclizeAPI_0.4.sol';

contract Bet is usingOraclize, Ownable {
  using SafeMath for uint256;

  enum Status { Cancelled, Active }
  enum Winner { Undecided, Player1, Player2, Draw }

  uint8 private constant FEE_PERCENT = 1;
  uint256 private constant MIN_SUGGESTCONFIRM_DURATION = 6 hours;
  uint256 private constant CLAIM_EXPIRES_AFTER = 8 weeks;
  uint8 private constant MAX_GOALS = 25;

  Status public status = Status.Active;

  uint8 public matchId;
  string public apiMatchId;
  string public matchContext;
  string public p1;
  string public p2;
  bool public isGroupPhase;
  uint256 public timeBettingOpens;
  uint256 public timeBettingCloses;
  uint256 public timeMatchEnds;
  uint256 public timeFetchStarts;
  uint256 public timeSuggestConfirmEnds;
  uint256 public timeClaimsExpire;

  event FetchingFailed(uint256 balance, uint256 fetchAttempt, uint256 MAX_FETCH_ATTEMPTS);
  event WinnerSuggested(Winner winner);
  event WinnerConfirmed(Winner winner);
  event BettingCancelled(string p1, string p2);

  uint256 private MAX_GAS_PRICE = 6e9; // 8GWei. Not constant so that it can be increased by the owner in case of higher demands in the future
  //uint256 private constant GAS_LIMIT = 300000; // works: 300000
  uint256 private constant GAS_LIMIT_MATCHSTATUS = 225000; // works: 300000
  uint256 private constant GAS_LIMIT_GOALS = 240000; // works: 300000
  uint256 private constant GAS_LIMIT_GOALS_PENALTY = 60000; // works: 300000
  // Best case (api has result after match ends): Min 3 fetches, max 5 fetches.
  // Add a buffer of 4 fetches (4 hours since 1 fetch/h)
  // --> 9 fetches max. Can be reset when refunded (see fundFetching())
  uint256 private constant MAX_FETCH_ATTEMPTS = 9; // One fetch costs around 0.8-1.2 USD
  uint256 private constant FETCH_INTERVAL = 60*60; // 60min in seconds
  string private URL;
  uint256 public fetchAttempt;
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
  bool public winnerSuggested = false;
  bool public winnerConfirmed = false;
  bool public ownerCalledConfirmFunction = false;
  Winner public winner; // default = 0, meaning Undecided

  string public test;

  uint256 public pool;
  uint256 public payoutPool;
  uint256 public remainingPayoutPool;
  uint256 public feeEarning;
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

  modifier canStartFetch() {
      require(now > timeFetchStarts);
      _;
  }

  modifier isSuggestConfirmPhase() {
      require(now > timeFetchStarts && now <= timeSuggestConfirmEnds, 'It is too early or too late to suggest/confirm a winner');
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
      if (now > timeSuggestConfirmEnds && winnerConfirmed == false) {
        cancelInternal()
      } else {
        _;
      }
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
        (winner == Winner.Player1 && betsPlayer1[msg.sender] > 0) ||
        (winner == Winner.Player2 && betsPlayer2[msg.sender] > 0) ||
        (winner == Winner.Draw && ((betsPlayer1[msg.sender] > 0) || (betsPlayer2[msg.sender] > 0)))
      );
      _;
  }

  modifier hasBets() {
      require(betsPlayer1[msg.sender] > 0 || betsPlayer2[msg.sender] > 0);
      _;
  }

  modifier startFetchingIfUnstarted() {
      if (isFetchingStarted == false) {
          fetchMatchStatus(0); // 0 == fetch now, without delay
          isFetchingStarted = true;
      } else {
          _;
      }
  }

  /*
    Helper functions
  */
  function getMinOraclizeGasCost() public returns (uint256) {
      return oraclize_getPrice("URL", GAS_LIMIT_GOALS);
  }

  function isValidWinner(uint8 _winner) private view returns (bool) {
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
      uint8 _matchId,
      string _apiMatchId,
      string _matchContext,
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
      
      matchId = _matchId;
      apiMatchId = _apiMatchId;
      matchContext = _matchContext;
      p1 = _p1;
      p2 = _p2;
      isGroupPhase = _isGroupPhase;
      URL = 'https://mohoff.de/live.txt';//strConcat('http://api.football-data.org/v1/fixtures/', apiMatchId);
      _setTimes(_matchStart, _durationBetting, _durationSuggestConfirm);
  }

  // public for testing
  function _setTimes(uint256 _matchStart, uint256 _durationBetting, uint256 _durationSuggestConfirm) public {
      require(_durationSuggestConfirm >= MIN_SUGGESTCONFIRM_DURATION); // longer than 2h in case max match duration is reached (overtimes + penalty shootout)

      // Miners can cheat on block timestamp with a tolerance of 900 seconds.
      // That's why betting is closed 900 seconds before match start.
      timeBettingCloses = _matchStart - 900 seconds;
      timeBettingOpens = _matchStart - _durationBetting;
      timeMatchEnds = timeBettingCloses + 105 minutes;
      timeFetchStarts = timeMatchEnds + 30 minutes;
      timeSuggestConfirmEnds = _matchStart + _durationSuggestConfirm;
      timeClaimsExpire = timeSuggestConfirmEnds + 8 weeks;
  }

  /* OLD BET FUNCTION: gas: 93620,  93627, 94136 */
  /* OLD BET FUNCTION: KOVAN: 54857 */

  // KOVAN: 84260
  function betOnPlayer1() external payable
      isNotCancelled
      isBettingPhase
      hasWei
  {
      betsPlayer1[msg.sender] = betsPlayer1[msg.sender].add(msg.value);
      numBetsPlayer1 += 1;
      totalPlayer1 = totalPlayer1.add(msg.value);
  }

  // 53534, 83534
  function betOnPlayer2() external payable
      isNotCancelled
      isBettingPhase
      hasWei
  {
      betsPlayer2[msg.sender] = betsPlayer2[msg.sender].add(msg.value);
      numBetsPlayer2 += 1;
      totalPlayer2 = totalPlayer2.add(msg.value);
  }


  /* kovan: 97000 gas, 106694, 106716 */
  // gas used when not first call (second or higher call): 76716
  // oraclize fee paid: 0.0018277 ether
  function fetchMatchStatus(uint256 _delay) private {
      string memory query = strConcat('json(', URL, ').fixture.status');
      queryStatus = fetch(query, _delay, GAS_LIMIT_MATCHSTATUS);
  }

  function fetchGoalsP1(uint256 _delay, bool _isPenalty) private {
      string memory query;

      if (_isPenalty == true) {
        query = strConcat('json(', URL, ').fixture.result.penaltyShootout.goalsHomeTeam');
        queryGoalsP1 = fetch(query, _delay, GAS_LIMIT_GOALS_PENALTY);
      } else {
        query = strConcat('json(', URL, ').fixture.result.goalsHomeTeam');
        queryGoalsP1 = fetch(query, _delay, GAS_LIMIT_GOALS);
      }
  }

  function fetchGoalsP2(uint256 _delay, bool _isPenalty) private {
      string memory query;

      if (_isPenalty == true) {
        query = strConcat('json(', URL, ').fixture.result.penaltyShootout.goalsAwayTeam');
        queryGoalsP2 = fetch(query, _delay, GAS_LIMIT_GOALS_PENALTY);
      } else {
        query = strConcat('json(', URL, ').fixture.result.goalsAwayTeam');
        queryGoalsP2 = fetch(query, _delay, GAS_LIMIT_GOALS);
      }
  }

  function fetch(string _query, uint256 _delay, uint256 _gaslimit) private
      returns (bytes32)
  {
      if (address(this).balance > oraclize_getPrice("URL", _gaslimit) &&
          fetchAttempt < MAX_FETCH_ATTEMPTS)
      {
          fetchAttempt = fetchAttempt.add(1);
          return oraclize_query(_delay, 'URL', _query, _gaslimit);  
      } else {
          status = Status.Cancelled;
          emit FetchingFailed(address(this).balance, fetchAttempt, MAX_FETCH_ATTEMPTS);
          return 0x1;
      }
  }


  // when match is FINISHED the first time: 212461
  // when match is IN_PLAY: 102053
  // retrieve goals: 73773, 229709 (paid 2x 0.0003877 fee)
  // retrieve penalty goals: 43773, 56538
  function __callback(bytes32 myid, string response) public
      onlyOraclize
      isNotWinnerSuggested
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

  function _handleMatchStatusResponse(string response) private {
      if (isFinished(response)) {
          matchFinished = true;

          fetchGoalsP1(0, false);
          fetchGoalsP2(0, false);
      } else {
          fetchMatchStatus(FETCH_INTERVAL);
      }
  }

  function _handleGoalsP1Response(string strGoals) private {
      uint goals = parseInt(strGoals);
      if (goals > MAX_GOALS) {
          fetchGoalsP1(FETCH_INTERVAL, fetchingPenaltyGoals);
      } else {
          goalsP1 = goals;
          goalsP1Fetched = true;

          if (goalsP2Fetched == true) {
              _suggestWinner(goalsP1, goalsP2);
          }
      }
  }

  function _handleGoalsP2Response(string strGoals) private {
      uint goals = parseInt(strGoals);
      if (goals > MAX_GOALS) {
          fetchGoalsP2(FETCH_INTERVAL, fetchingPenaltyGoals);
      } else {
          goalsP2 = goals;
          goalsP2Fetched = true;

          if (goalsP1Fetched == true) {
              _suggestWinner(goalsP1, goalsP2);
          }
      }
  }

  function _suggestWinner(uint _goalsP1, uint _goalsP2) private {
      if (_goalsP1 > _goalsP2) {
          winner = Winner.Player1;
          winnerSuggested = true;
          emit WinnerSuggested(winner);
      } else if (_goalsP1 < _goalsP2) {
          winner = Winner.Player2;
          winnerSuggested = true;
          emit WinnerSuggested(winner);
      } else {
          // same amount of goals
          if (isGroupPhase == true) {
              winner = Winner.Draw;
              winnerSuggested = true;
              emit WinnerSuggested(winner);
          } else {
              // We are in knockout-stage, thus Winner.Draw not possible
              // --> Fetch penalty shootout goals
              // If still P1 and P2 have same amount of goals (shouldn't happen), MAX_FETCH_ATTEMPTS should eventually cancel the bet
              fetchingPenaltyGoals = true;
              goalsP1Fetched = false;
              goalsP2Fetched = false;
              fetchGoalsP1(0, true);
              fetchGoalsP2(0, true);
          }
      }
  }

  // gas: 106286, 126500
  // WHEN already confirmed (fail): 24450
  function confirmWinner(uint8 _winnerAsInt) external
      onlyOwner
      isNotCancelled
      isWinnerSuggested
      cancelIfTooLateForConfirmation
      isFirstConfirmCall
  {
      require(isValidWinner(_winnerAsInt));
      ownerCalledConfirmFunction = true;

      if (winner == Winner(_winnerAsInt)) {
          winnerConfirmed = true;

          pool = totalPlayer1.add(totalPlayer2);

          if (pool > 0) {
              uint256 feeAmount = pool.mul(FEE_PERCENT).div(100);
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

  function cancel() public
      onlyOwner
  {
      cancelInternal();
  }

  function cancelInternal() private
      isNotCancelled
      canBeCancelled
  {
      status = Status.Cancelled;
      payoutPool = totalPlayer1.add(totalPlayer2);

      emit BettingCancelled(p1, p2);
  }

  function updateStatus() external
      isNotCancelled
      canBeCancelled
  {
      if (now > timeSuggestConfirmEnds && winnerConfirmed == false) {
        cancelInternal()
      }
  }

  // KOVAN start fetch (enough gas): 142302
  // kOVAN fee transfered to oraclize: 0.0013777
  // KOVAN claim success: 90976, 45976, 29300, 22150
  function claimWinOrDraw() external
      isNotCancelled
      canStartFetch
      cancelIfTooLateForConfirmation
      startFetchingIfUnstarted
      isWinnerConfirmed
      isClaimNotExpired
  {
      uint256 payout;
      // Check if msg.sender has bets on winner team
      if (winner == Winner.Player1 && betsPlayer1[msg.sender] > 0) {
          payout = payoutPool.mul(betsPlayer1[msg.sender]).div(totalPlayer1);
          betsPlayer1[msg.sender] = 0;
      } else if (winner == Winner.Player2 && betsPlayer2[msg.sender] > 0) {
          payout = payoutPool.mul(betsPlayer2[msg.sender]).div(totalPlayer2);
          betsPlayer2[msg.sender] = 0;
      } else if (winner == Winner.Draw &&
          (betsPlayer1[msg.sender] > 0 || betsPlayer2[msg.sender] > 0))
      {
          payout = betsPlayer1[msg.sender] + betsPlayer2[msg.sender];
          betsPlayer1[msg.sender] = 0;
          betsPlayer2[msg.sender] = 0;
      } else {
          revert();
      }

      require(remainingPayoutPool >= payout);
      remainingPayoutPool = remainingPayoutPool.sub(payout);

      msg.sender.transfer(payout);
  }

  function claimRefund() external
      isCancelled
      isClaimNotExpired
      hasBets
  {
      uint256 refund = betsPlayer1[msg.sender].add(betsPlayer2[msg.sender]);
      betsPlayer1[msg.sender] = 0;
      betsPlayer2[msg.sender] = 0;

      require(remainingPayoutPool >= refund);
      remainingPayoutPool = remainingPayoutPool.sub(refund);
      
      msg.sender.transfer(refund);
  }

  function claimExpired() external
      onlyOwner
      isExpiredPhase
  {
      payoutPool = 0;

      msg.sender.transfer(address(this).balance);
  }

  function fundFetching() public payable
      isNotCancelled
      isNotWinnerSuggested
      isSuggestConfirmPhase
  {
      // Fund must be substantial because we reset fetchAttempts.
      // Contract balance can be drained if fetchAttempt is reset
      // every time this function is called, when the fetches
      // 0->MAX_FETCH_ATTEMPTS cost more than funded `msg.value`.
      require(msg.value >= 1e16); // 1/100 ether = ~7 dollar
      fetchAttempt = 0;
      isFetchingStarted = true;
      fetchMatchStatus(0);
  }

  function increaseGasPriceBy(uint256 _extra) external
      onlyOwner
  {
      MAX_GAS_PRICE = MAX_GAS_PRICE.add(_extra);
  }

  /* fallback function */
  function () external payable {
      revert(); 
  }
}
