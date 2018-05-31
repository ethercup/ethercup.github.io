var Bet = artifacts.require('Bet');

var getTimestampNow = () => {
  return Math.floor(Date.now()/1000)
}

const gameId = '165069'
const group = 'A'
const p1 = 'Germany'
const p2 = 'Russia'
const isGroupPhase = true
const matchStart = getTimestampNow()+3600*24*8
const durationBetting = 3600*24*7
const durationSuggestConfirm = 3600*24*2

var getBetWithBettingInactive = (owner) => {
  return Bet.new(
    gameId,
    group,
    p1,
    p2,
    isGroupPhase,
    matchStart,
    durationBetting,
    durationSuggestConfirm,
    {from: owner, value: 0}
  );
}

var assertThrow = async (fn, args) => {
  try {
    await fn.apply(null, args)
    assert(false, 'the contract should throw here')
  } catch (error) {
    assert(
      /invalid opcode/.test(error) || /revert/.test(error),
      `the error message should be invalid opcode or revert, the error was ${error}`
    )
  }
}

const testBet = async (contract, playerBet, meta) => {
    await contract.bet(playerBet, meta);
}


    // it('should initialize contract correctly', async () => {
    //   assert.equal(await contract.p1(), p1, 'p1 isn\'t initialized as expected')
    //   assert.equal(await contract.p2(), p2, 'p2 isn\'t initialized as expected')
    //   assert.equal(await contract.isGroupPhase(), isGroupPhase, 'isGroupPhase isn\'t initialized as expected')
    //   assert.equal(await contract.timeBettingCloses(), (matchStart - 900), "timeBettingCloses isn't initialized as expected")
    //   assert.equal(await contract.timeBettingOpens(), await contract.timeBettingCloses() - durationBetting, "timeBettingOpens isn't initialized as expected")
    //   assert.equal(await contract.timeMatchEnds(), await contract.timeBettingCloses() + 105*60, "timeMatchEnds isn't initialized as expected")
    //   assert.equal(await contract.timeSuggestConfirmEnds(), await contract.timeMatchEnds() + durationSuggestConfirm, "timeMatchEnds isn't initialized as expected")
    //   assert.equal(await contract.timeClaimsExpire(), await contract.timeSuggestConfirmEnds() + 8*7*24*60*60, "timeClaimsExpire isn't initialized as expected")
    // })




/*
    PHASE: BettingInactive
*/
describe('When in BettingInactive phase', () => {
  contract('Bet', accounts => {

    let contract
    const owner = accounts[0]
    const sender = accounts[1]
    const betAmount = 5

    beforeEach('setup contract for each test', async () => {
        contract = await getBetWithBettingInactive(owner);
    })

    it('should NOT allow user to bet', async () => {
      await assertThrow(contract.betOnPlayer1, {from: sender, value: betAmount})
      await assertThrow(contract.betOnPlayer2, {from: sender, value: betAmount})
    })

    it('should NOT be able for the owner to call claimExpired', async () => {
      await assertThrow(contract.claimExpired, {from: owner, value: 0})
    })

    it('should NOT allow a normal user to call confirmWinner/cancel/claimWinOrDraw/claimCancelled/claimExpired', async () => {
      await assertThrow(contract.confirmWinner, [1, {from: sender, value: 0}])
      await assertThrow(contract.cancel, [{from: sender, value: 0}])
      await assertThrow(contract.claimWinOrDraw, [{from: sender, value: 0}])
      await assertThrow(contract.claimCancelled, [{from: sender, value: 0}])
      await assertThrow(contract.claimExpired, [{from: sender, value: 0}])
    })

    it('should NOT allow owner to suggest and decide another winner', async () => {
      await assertThrow(contract.suggestWinner, [1, {from: owner, value: 0}])
      await assertThrow(contract.confirmWinner, [1, {from: owner, value: 0}])
    })

    it('should allow owner to cancel', async () => {
      const expectedStatus = 1; // cancelled

      await contract.cancel({from: owner, value: 0})

      const status = await contract.status()
      assert.equal(status, expectedStatus, 'phase should be BettingCancelled')
    })
  })
})

/*
    PHASE: Phase.BettingOpen
*/
describe('When in BettingOpen phase', () => {
  contract('Bet', accounts => {

    let contract
    const owner = accounts[0]
    const sender = accounts[1]
    const betAmount = 5

    beforeEach('setup contract for each test', async () => {
        contract = await getBetWithBettingInactive(owner);
        await contract._setTimes(matchStart-3600*24*3, durationBetting, durationSuggestConfirm)
    })

    it('should NOT be able for the owner to call claimExpired', async () => {
      await assertThrow(contract.claimExpired, [{from: owner, value: 0}])
    })

    it('should NOT allow a normal user to call confirmWinner/cancel/claimWinOrDraw/claimCancelled/claimExpired', async () => {
      await assertThrow(contract.confirmWinner, [1, {from: sender, value: 0}])
      await assertThrow(contract.cancel, [{from: sender, value: 0}])
      await assertThrow(contract.claimWinOrDraw, [{from: sender, value: 0}])
      await assertThrow(contract.claimCancelled, [{from: sender, value: 0}])
      await assertThrow(contract.claimExpired, [{from: sender, value: 0}])
    })

    it('should deposit ether correctly and update numBets and totalBets', async () => {
      const expectedAmount = betAmount
      // This should return TRUE?
      await contract.betOnPlayer1({from: sender, value: betAmount})

      const bet = await contract.betsPlayer1(sender)
      const numBets = await contract.numBetsPlayer1()
      const totalBets = await contract.totalPlayer1()
      assert.equal(bet, expectedAmount, 'betting ether should update the sender\'s betting balance accordingly')
      assert.equal(numBets, 1, 'betting ether once should increase number of bets')
      assert.equal(totalBets, expectedAmount, 'betting ether should update the total amount of bets')
    })

    it('should update balances correctly when user bets twice', async () => {
      const expectedAmount = betAmount * 2
      await contract.betOnPlayer1({from: sender, value: betAmount})
      await contract.betOnPlayer1({from: sender, value: betAmount})

      const bet = await contract.betsPlayer1(sender)
      const numBets = await contract.numBetsPlayer1()
      const totalBets = await contract.totalPlayer1()
      assert.equal(bet, expectedAmount, 'betting ether should update the sender\'s betting balance accordingly')
      assert.equal(numBets, 2, 'betting ether once should increase number of bets')
      assert.equal(totalBets, expectedAmount, 'betting ether should update the total amount of bets')
    })

    it('should throw when bet includes 0 wei', async () => {
      await assertThrow(contract.betOnPlayer1, {from: sender, value: 0})
      await assertThrow(contract.betOnPlayer2, {from: sender, value: 0})
    })

    it('should allow owner to cancel', async () => {
      const expectedStatus = 1; // cancelled

      await contract.cancel({from: owner, value: 0})

      const status = await contract.status()
      assert.equal(status, expectedStatus, 'phase should be BettingCancelled')
    })
  })
})

/*
    PHASE: Phase.BettingClosed
*/
describe('When in BettingClosed phase', () => {
  contract('Bet', accounts => {

    let contract
    const owner = accounts[0]
    const sender = accounts[1]
    const betAmount = 5

    beforeEach('setup contract for each test', async () => {
        contract = await getBetWithBettingInactive(owner);
        await contract._setTimes(matchStart-3600*24*3, durationBetting, durationSuggestConfirm)
        await contract.betOnPlayer1({from: sender, value: betAmount})
        await contract._setTimes(matchStart-3600*24*5+3600, durationBetting, durationSuggestConfirm)
    })

    it('should NOT allow to bet more', async () => {
      await assertThrow(contract.betOnPlayer1, {from: sender, value: betAmount})
    })

    it('should NOT be able for the owner to call claimExpired', async () => {
      await assertThrow(contract.claimExpired, [{from: owner, value: 0}])
    })

    it('should NOT allow a normal user to call confirmWinner/cancel/claimWinOrDraw/claimCancelled/claimExpired', async () => {
      await assertThrow(contract.confirmWinner, [1, {from: sender, value: 0}])
      await assertThrow(contract.cancel, [{from: sender, value: 0}])
      await assertThrow(contract.claimWinOrDraw, [{from: sender, value: 0}])
      await assertThrow(contract.claimCancelled, [{from: sender, value: 0}])
      await assertThrow(contract.claimExpired, [{from: sender, value: 0}])
    })

    it('should allow owner to cancel', async () => {
      const expectedStatus = 1; // cancelled

      await contract.cancel({from: owner, value: 0})

      const status = await contract.status()
      assert.equal(status, expectedStatus, 'phase should be BettingCancelled')
    })
  })
})



/*
    PHASE: Phase.BettingWinnerSuggested
*/
describe('When in BettingWinnerSuggested phase', () => {
  contract('Bet', accounts => {

    let contract
    const owner = accounts[0]
    const sender = accounts[1]
    const betAmount = 5

    beforeEach('setup contract for each test', async () => {
        contract = await getBetWithBettingInactive(owner);
        await contract._setTimes(matchStart-3600*24*3, durationBetting, durationSuggestConfirm)
        await contract.betOnPlayer1({from: sender, value: betAmount})
        await contract._setTimes(matchStart-(3600*24*8+3600*4), durationBetting, durationSuggestConfirm)
    })

    it('should NOT allow to bet more', async () => {
      await assertThrow(contract.betOnPlayer1, {from: sender, value: betAmount})
    })

    it('should NOT be able for the owner to call claimExpired', async () => {
      await assertThrow(contract.claimExpired, {from: owner, value: 0})
    })

    it('should NOT allow a normal user to call confirmWinner/cancel/claimWinOrDraw/claimCancelled/claimExpired', async () => {
      await assertThrow(contract.confirmWinner, [1, {from: sender, value: 0}])
      await assertThrow(contract.cancel, [{from: sender, value: 0}])
      await assertThrow(contract.claimWinOrDraw, [{from: sender, value: 0}])
      await assertThrow(contract.claimCancelled, [{from: sender, value: 0}])
      await assertThrow(contract.claimExpired, [{from: sender, value: 0}])
    })

    it('should allow owner to confirm winner, update winners correctly and set flags', async () => {
      const expectedWinner = 1;

      await contract.suggestWinner(expectedWinner, {from: owner, value: 0})
      await contract.confirmWinner(expectedWinner, {from: owner, value: 0})

      const winner = await contract.winner()
      const winnerSuggested = await contract.winnerSuggested()
      const winnerConfirmed = await contract.winnerConfirmed()

      assert.equal(winnerSuggested, true, 'winnerSuggested flag should be true')
      assert.equal(winnerConfirmed, true, 'winnerConfirmed flag should be true')
      assert.equal(winner, expectedWinner, 'when owner confirms winner, winner should be as expected')
    })

    it('should cancel bet when confirmedWinner is NOT equal to suggestedWinner', async () => {
      const expectedStatus = 1
      const expectedSuggestedWinner = 1
      const expectedWinner = 2

      await contract.suggestWinner(expectedSuggestedWinner, {from: owner, value: 0})
      await contract.confirmWinner(expectedWinner, {from: owner, value: 0})


      const status = await contract.status()
      const winnerSuggested = await contract.winnerSuggested()
      const winnerConfirmed = await contract.winnerConfirmed()

      assert.equal(winnerSuggested, true, 'winnerSuggested flag should be true')
      assert.equal(winnerConfirmed, false, 'winnerConfirmed flag should be true')
      assert.equal(status, expectedStatus, 'status should be set to cancelled')
    })

    it('should allow owner to cancel', async () => {
      const expectedStatus = 1; // cancelled

      await contract.cancel({from: owner, value: 0})

      const status = await contract.status()
      assert.equal(status, expectedStatus, 'phase should be BettingCancelled')
    })
  })
})



/*
    PHASE: Phase.BettingDecided
*/
describe('When in BettingDecided phase and claims haven\'t expired yet', () => {
  contract('Bet', accounts => {

    let contract
    const owner = accounts[0]
    const user1BettedOnWinner = accounts[1]
    const user2BettedOnWinner = accounts[2]
    const user3BettedOnLoser = accounts[3]
    const winner = 1
    const notWinner = 2

    const betAmount = 100000
    const totalBetAmount = betAmount * 3
    const expectedFeeEarning = totalBetAmount * 0.01
    const expectedPayoutPool = totalBetAmount - expectedFeeEarning


    beforeEach('setup contract for each test', async () => {
        contract = await getBetWithBettingInactive(owner);
        await contract._setTimes(matchStart-3600*24*3, durationBetting, durationSuggestConfirm)
        await contract.betOnPlayer1({from: user1BettedOnWinner, value: betAmount})
        await contract.betOnPlayer1({from: user2BettedOnWinner, value: betAmount})
        await contract.betOnPlayer2({from: user3BettedOnLoser, value: betAmount})
        await contract._setTimes(matchStart-(3600*24*8+3600*4), durationBetting, durationSuggestConfirm)
        await contract.suggestWinner(winner, {from: owner, value: 0})
        await contract.confirmWinner(winner, {from: owner, value: 0})
    })

    it('should NOT allow to bet more', async () => {
      await assertThrow(contract.betOnPlayer1, {from: user1BettedOnWinner, value: betAmount})
    })

    it('should NOT allow owner to suggest and decide another winner', async () => {
      await assertThrow(contract.suggestWinner, [1, {from: owner, value: 0}])
      await assertThrow(contract.confirmWinner, [1, {from: owner, value: 0}])
    })

    it('should NOT allow owner to cancel', async () => {
      await assertThrow(contract.cancel, [{from: owner, value: 0}])
    })

    it('should NOT allow a normal user to call confirmWinner/cancel/claimCancelled/claimExpired', async () => {
      await assertThrow(contract.confirmWinner, [1, {from: user1BettedOnWinner, value: 0}])
      await assertThrow(contract.cancel, {from: user1BettedOnWinner, value: 0})
      await assertThrow(contract.claimCancelled, {from: user1BettedOnWinner, value: 0})
      await assertThrow(contract.claimExpired, {from: user1BettedOnWinner, value: 0})
    })

    it('should NOT be able for the owner to call claimExpired', async () => {
      await assertThrow(contract.claimExpired, {from: owner, value: 0})
    })

    it('should throw when user tries to claim wins but has no bets', async () => {
      await assertThrow(contract.claimWinOrDraw, {from: owner, value: 0})
    })

    it('should throw when user tries to claim wins but betted on wrong player', async () => {
      await assertThrow(contract.claimWinOrDraw, {from: user3BettedOnLoser, value: 0})
    })

    it('should set feeAmount and payoutPool correctly', async () => {
      const fee = await contract.feeEarning()
      const payoutPool = await contract.payoutPool()

      assert.equal(fee, expectedFeeEarning, 'feeEarnings should be as expected')
      assert.equal(payoutPool, expectedPayoutPool, 'payoutPool should be as expected')
    })

    it('should allow user to claim his won shares if he betted correctly', async () => {
      await contract.claimWinOrDraw({from: user1BettedOnWinner})

      betsSender = await contract.betsPlayer1(user1BettedOnWinner)
      payoutPool = await contract.payoutPool()

      assert.equal(betsSender, 0, 'sender bets should be 0 once he claimed his wins')
      assert.equal(payoutPool, expectedPayoutPool/2, 'payout pool should be divided among the two winners')
    })
  })
})


/*
    PHASE: Phase.BettingCancelled
*/
describe('When in BettingCancelled phase', () => {
  contract('Bet', accounts => {

    let contract
    const owner = accounts[0]
    const user1BettedOnWinner = accounts[1]
    const user2BettedOnWinner = accounts[2]
    const user3BettedOnLoser = accounts[3]
    const user4 = accounts[4]
    const winner = 1
    const notWinner = 2

    const betAmount = 100000
    const totalBetAmount = betAmount * 3
    const expectedFeeEarning = totalBetAmount * 0.01
    const expectedPayoutPool = totalBetAmount - expectedFeeEarning


    beforeEach('setup contract for each test', async () => {
        contract = await getBetWithBettingInactive(owner);
        await contract._setTimes(matchStart-3600*24*3, durationBetting, durationSuggestConfirm)
        await contract.betOnPlayer1({from: user1BettedOnWinner, value: betAmount})
        await contract.betOnPlayer1({from: user2BettedOnWinner, value: betAmount})
        await contract.betOnPlayer2({from: user3BettedOnLoser, value: betAmount})
        await contract._setTimes(matchStart-(3600*24*8+3600*4), durationBetting, durationSuggestConfirm)
        await contract.suggestWinner(winner, {from: owner, value: 0})
        await contract.cancel({from: owner, value: 0})
    })

    it('should NOT allow to bet more', async () => {
      await assertThrow(contract.betOnPlayer1, {from: user1BettedOnWinner, value: betAmount})
    })

    it('should NOT be able for the owner to call cancel again', async () => {
      await assertThrow(contract.cancel, {from: owner, value: 0})
    })

    it('should NOT be able for the owner to call claimExpired', async () => {
      await assertThrow(contract.claimExpired, {from: owner, value: 0})
    })

    it('should NOT be able for user to call claimWinOrDraw', async () => {
      await assertThrow(contract.claimWinOrDraw, {from: user1BettedOnWinner, value: 0})
    })

    it('should NOT allow user to reclaim anything when he hasn\'t put any bet', async () => {
      await assertThrow(contract.claimCancelled, {from: user4, value: 0})
    })

    it('should allow user to reclaim his bets', async () => {
      await contract.claimCancelled({from: user1BettedOnWinner, value: 0})

      betUser1 = await contract.betsPlayer1(user1BettedOnWinner)
      payoutPool = await contract.payoutPool()
      assert.equal(betUser1, 0, 'betPlayer1(user1) should be 0 as he reclaimed his bet')
      assert.equal(payoutPool, totalBetAmount - betAmount, 'reclaiming bets should reduce payoutPool accordingly')
    })
  })
})

describe('When in BettingDecidedExpired phase', () => {
  contract('Bet', accounts => {

    let contract
    const owner = accounts[0]
    const user1BettedOnWinner = accounts[1]
    const user2BettedOnWinner = accounts[2]
    const user3BettedOnLoser = accounts[3]
    const winner = 1
    const notWinner = 2

    const betAmount = 100000
    const totalBetAmount = betAmount * 3
    const expectedFeeEarning = totalBetAmount * 0.01
    const expectedPayoutPool = totalBetAmount - expectedFeeEarning


    beforeEach('setup contract for each test', async () => {
        contract = await getBetWithBettingInactive(owner);
        await contract._setTimes(matchStart-3600*24*3, durationBetting, durationSuggestConfirm)
        await contract.betOnPlayer1({from: user1BettedOnWinner, value: betAmount})
        await contract.betOnPlayer1({from: user2BettedOnWinner, value: betAmount})
        await contract.betOnPlayer2({from: user3BettedOnLoser, value: betAmount})
        await contract._setTimes(matchStart-(3600*24*8+3600*4), durationBetting, durationSuggestConfirm)
        await contract.suggestWinner(winner, {from: owner, value: 0})
        await contract.confirmWinner(winner, {from: owner, value: 0})
        await contract._setTimes(matchStart-3600*24*7*10, durationBetting, durationSuggestConfirm)
    })

    it('should NOT allow to bet more', async () => {
      await assertThrow(contract.betOnPlayer1, {from: user1BettedOnWinner, value: betAmount})
    })

    it('should NOT be able for the owner to call cancel again', async () => {
      await assertThrow(contract.cancel, {from: owner, value: 0})
    })

    it('should NOT be able for user to call claimWinOrDraw', async () => {
      await assertThrow(contract.claimWinOrDraw, {from: owner, value: 0})
    })
    
    it('should NOT be able for user to call claimCancelled', async () => {
      await assertThrow(contract.claimCancelled, {from: user1BettedOnWinner, value: 0})
    })

    it('should be able for the owner to call claimExpired', async () => {
      await contract.claimExpired({from: owner, value: 0})

      payoutPool = await contract.payoutPool()
      assert.equal(payoutPool, 0, 'payoutPool should be 0')
    })
  })
})


