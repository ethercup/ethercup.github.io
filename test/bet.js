var Bet = artifacts.require("Bet");
//const assertThrow = require('./helpers');

var getTimestampNow = () => {
  return Math.floor(Date.now()/1000)
}

var getBetWithBettingOpen = () => {
  return Bet.new(
    "Germany",
    "Russia",
    true,
    getTimestampNow()+3600,
    100000,
    3600*24
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
// use before/beforeEeach to improve unit tests

describe('When initially deployed', () => {
  contract('Bet', accounts => {
    const sender = accounts[0]
    const betAmount = 5

    it("should have phase set to Inactive or BettingOpen", async () => {
      const contract = await getBetWithBettingOpen()

      const phase = await contract.phase()
      assert.ok(phase == 0 || phase == 1, 'Initial phase is not Inactive or BettingOpen')
    })
  })
})
describe('When in BettingOpen phase', () => {
  contract('Bet', accounts => {
    const sender = accounts[0]
    const betAmount = 5
    /*before('setup Bet contract in BettingOpen phase', async () => {
      const contract = await getBetWithBettingOpen()
      const sender = accounts[0]
    })*/

    it("should deposit ether correctly and update numBets and totalBets", async () => {
      const contract = await getBetWithBettingOpen()
      const expectedAmount = betAmount
      // This should return TRUE?
      await contract.bet(1, {from: sender, value: betAmount})

      const bet = await contract.betsPlayer1(sender)
      const numBets = await contract.numBetsPlayer1()
      const totalBets = await contract.totalPlayer1()
      assert.equal(bet, expectedAmount, 'betting ether should update the sender\'s betting balance accordingly')
      assert.equal(numBets, 1, 'betting ether once should increase number of bets')
      assert.equal(totalBets, expectedAmount, 'betting ether should update the total amount of bets')
    })

    it("should update balances correctly when user bets twice", async () => {
      const contract = await getBetWithBettingOpen()
      const expectedAmount = betAmount * 2
      await contract.bet(1, {from: sender, value: betAmount})
      await contract.bet(1, {from: sender, value: betAmount})

      const bet = await contract.betsPlayer1(sender)
      const numBets = await contract.numBetsPlayer1()
      const totalBets = await contract.totalPlayer1()
      assert.equal(bet, expectedAmount, 'betting ether should update the sender\'s betting balance accordingly')
      assert.equal(numBets, 2, 'betting ether once should increase number of bets')
      assert.equal(totalBets, expectedAmount, 'betting ether should update the total amount of bets')
    })

    it("should be in phase BettingOpen after first bet is placed", async () => {
      const contract = await getBetWithBettingOpen()
      const expectedPhase = 1;

      await contract.bet(1, {from: sender, value: betAmount})

      const phase = await contract.phase()
      assert.equal(phase, expectedPhase, 'after the first bet, the phase should be BettingOpen')
    })

    it("should throw when not betted on player 1 or 2", async () => {
      const contract = await getBetWithBettingOpen()

      // This syntax doesn't work when FAIL is expected
      //await contract.bet(3, {from: sender, value: betAmount})

      await assertThrow(contract.bet, [0, {from: sender, value: betAmount}])
      await assertThrow(contract.bet, [3, {from: sender, value: betAmount}])
    })
  })
})


