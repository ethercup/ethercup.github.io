var Web3 = require('web3')
var TruffleContract = require('truffle-contract')
var HDWalletProvider = require('truffle-hdwallet-provider');
var fs = require('fs')

const mnemonic = fs.readFileSync('./mnemonic.txt', 'utf8', function (err, data) {
  if (err) throw err;
  console.log(data);
});

function fixTruffleContractCompatibilityIssue(contract) {
    if (typeof contract.currentProvider.sendAsync !== "function") {
        contract.currentProvider.sendAsync = function() {
            return contract.currentProvider.send.apply(
                contract.currentProvider, arguments
            );
        };
    }
    return contract;
}

const provider = new HDWalletProvider(mnemonic, "http://localhost:8545", 0, 5)
const web3 = new Web3(provider)

const GASPRICE = 6e9
const OWNER = '0x4f3e7B7900e1352a43EA1a6aA8fc7F1FC03EfAc9'.toLowerCase() //acc1

const ADDRESS_REGISTRY = '0x9540465c237EfB0C45a27741a845Ecb1558b878B'.toLowerCase()
const ADDRESS_BET = '0xe78c408045663967Aa587dcD308A6FB09d855a85'.toLowerCase()

async function main() {
  // Unlock owner account
  //console.log(await web3.eth.personal.unlockAccount(OWNER, 'test'))

  var jsonBlob = require('../build/contracts/Bet.json')
  var jsonBlobReg = require('../build/contracts/BetRegistry.json')
  var betContract = TruffleContract(jsonBlob)
  var betRegistryContract = TruffleContract(jsonBlobReg)
  betContract.setProvider(provider)
  betRegistryContract.setProvider(provider)
  betContract.defaults({
    gasPrice: 6e9,
    from: OWNER
  })
  betRegistryContract.defaults({
    gasPrice: 6e9,
    from: OWNER
  })
  fixTruffleContractCompatibilityIssue(betContract) // workaround. see https://github.com/trufflesuite/truffle-contract/issues/57
  fixTruffleContractCompatibilityIssue(betRegistryContract)

  var bet = betContract.at(ADDRESS_BET)
  var betRegistry = betRegistryContract.at(ADDRESS_REGISTRY)

  console.log("BetRegistry nextIndex: " + await betRegistry.nextIndex.call())

  console.log("\nSTATUS: " + await bet.status.call())  
  console.log("P1: " + await bet.p1.call())
  console.log("P2: " + await bet.p2.call())
  console.log("matchContext: " + await bet.matchContext.call())

  console.log("\n---BETs---")
  console.log("betsPlayer1: " + await bet.betsP1.call(OWNER))
  console.log("betsPlayer2: " + await bet.betsP2.call(OWNER))
  console.log("numBetsPlayer1: " + await bet.numBetsP1.call())
  console.log("numBetsPlayer2: " + await bet.numBetsP2.call())
  console.log("totalPlayer1: " + await bet.totalP1.call())
  console.log("totalPlayer2: " + await bet.totalP2.call())

  console.log("\n---WINNER FETCH---")
  console.log("isFetchingStarted: " + await bet.isFetchingStarted.call())
  console.log("queryStatus: " + await bet.queryStatus.call())
  console.log("queryGoalsP1: " + await bet.queryGoalsP1.call())
  console.log("queryGoalsP2: " + await bet.queryGoalsP2.call())  
  console.log("matchFinished: " + await bet.matchFinished.call())
  console.log("fetchAttempt: " + await bet.fetchAttempt.call())
  // use then/catch here because a revert() is a feature here
  bet.fundingNeeded.call().then((result) => {
    console.log("fundingNeeded: " + result)
  }).catch(err => {
    console.log("fundingNeeded: NO")
  })
  
  console.log("timeBettingOpens: " + await bet.timeBettingOpens.call())
  console.log("timeBettingCloses: " + await bet.timeBettingCloses.call())
  console.log("timeMatchEnds: " + await bet.timeMatchEnds.call())
  console.log("timeSuggestConfirmEnds: " + await bet.timeFetchConfirmEnds.call())

  console.log("goalsP1: " + await bet.goalsP1.call())
  console.log("goalsP2: " + await bet.goalsP2.call())
  console.log("goalsP1Fetched: " + await bet.goalsP1Fetched.call())
  console.log("goalsP2Fetched: " + await bet.goalsP2Fetched.call())
  console.log("winner: " + await bet.winner.call())
  console.log("winnerFetched: " + await bet.winnerFetched.call())

  console.log("\n---WINNER CONFIRM---")
  console.log("winnerConfirmed: " + await bet.winnerConfirmed.call())
  console.log("pool: " + await bet.pool.call())
  console.log("payoutPool: " + await bet.payoutPool.call())
  console.log("remainingPayoutPool: " + await bet.remainingPayoutPool.call())
  console.log("feeEarning: " + await bet.feeEarning.call())
  process.exit()
}

main().catch(console.error)