var Web3 = require('web3')
var contract = require('truffle-contract')
var HDWalletProvider = require('truffle-hdwallet-provider');
var fs = require('fs')

const mnemonic = fs.readFileSync('./mnemonic.txt', 'utf8', function (err, data) {
  if (err) throw err;
  console.log(data);
});


// my metamask accounts
// var mnemonic = fs.readFile('../mnemonic.txt', function (err, data) {
//   if (err) throw err;
//   console.log(data);
// });
// if (typeof web3 !== 'undefined') {
//   web3 = new Web3(web3.currentProvider)
// } else {
//   // set the provider you want from Web3.providers
//   web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))
// }


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

async function main() {
  //const provider = new Web3.providers.HttpProvider("http://localhost:8545")
  const provider = new HDWalletProvider(mnemonic, "http://localhost:8545", 0, 5)
  const web3 = new Web3(provider)

  // INFURA:
  // if (typeof web3 !== 'undefined') {
  //     window.web3 = new Web3(web3.currentProvider)
  // } else {
  //     window.web3 = new Web3(new Web3.providers.HttpProvider('https://rinkeby.infura.io:443'))
  // }

  const migrationsAddress = '0x9866102e9ee2c5d668bf70c8f50647fb725e4b0c'

  const betRegistryAddress = '0x9540465c237EfB0C45a27741a845Ecb1558b878B'
  const betAddress = '0x9119027c717f061eb599d350926d6729c7f12cad'

  const owner = '0x4f3e7B7900e1352a43EA1a6aA8fc7F1FC03EfAc9'.toLowerCase() //acc1
  const user1 = '0xCE1834593259431E36b3F7b68655A88d8Bf6ffca'.toLowerCase() //acc2
  const user2 = '0xA2DA2A177f0C9645c64124A61F5FcF08E281b0Da'.toLowerCase() //acc3
  const tenthEther = 1e17 // wei

  console.log(await web3.eth.personal.unlockAccount(owner, 'test'))
  console.log(await web3.eth.personal.unlockAccount(user1, 'test'))
  console.log(await web3.eth.personal.unlockAccount(user2, 'test'))
  
  var contract = require("truffle-contract")

  var jsonBlob = require('../build/contracts/Bet.json')
  var jsonBlobReg = require('../build/contracts/BetRegistry.json')
  var betContract = contract(jsonBlob)
  var betRegistryContract = contract(jsonBlobReg)
  betContract.setProvider(provider)
  betRegistryContract.setProvider(provider)
  betContract.defaults({
    gasPrice: 6e9,
  })
  betRegistryContract.defaults({
    gasPrice: 6e9,
  })
  fixTruffleContractCompatibilityIssue(betContract) // workaround. see https://github.com/trufflesuite/truffle-contract/issues/57
  fixTruffleContractCompatibilityIssue(betRegistryContract)

  // const promisify = (inner) =>
  //   new Promise((resolve, reject) =>
  //     inner((err, res) => {
  //       if (err) { reject(err) }

  //       resolve(res);
  //     })
  //   );
  // oralice_getprice: 1827700000000000, 1347700000000000
  
  var bet = betContract.at(betAddress)
  var betRegistry = betRegistryContract.at(betRegistryAddress)

  //await betRegistry.addBet(betAddress, {from: owner});

  //console.log(await bet.betOnPlayer1({from: owner, value: 0.5*tenthEther}))
  //console.log(await bet.betOnPlayer2({from: user1, value: 0.2*tenthEther})) //--> gets 0.0396
  //console.log(await bet.betOnPlayer2({from: user2, value: 0.3*tenthEther})) //--> gets 0.03564

  //console.log(await bet.claimWinOrDraw({from: user2}))
  //console.log(await bet.cancel({from: user1}))
  //console.log(await bet.confirmWinner(1, {from: user1}))
  //console.log(await bet.claimExpired({from: user1}))

  //console.log(await bet.confirmWinner(3, {from: owner}))
 
  //bet.claimWinOrDraw({from: owner})
  console.log("BetRegistry nextIndex: " + await betRegistry.nextIndex.call())

  console.log("\nSTATUS: " + await bet.status.call())  

  console.log("\n---BETs---")
  console.log("betsPlayer1: " + await bet.betsPlayer1.call(owner))
  console.log("betsPlayer2: " + await bet.betsPlayer2.call(owner))
  console.log("numBetsPlayer1: " + await bet.numBetsPlayer1.call())
  console.log("numBetsPlayer2: " + await bet.numBetsPlayer2.call())
  console.log("totalPlayer1: " + await bet.totalPlayer1.call())
  console.log("totalPlayer2: " + await bet.totalPlayer2.call())

  console.log("\n---WINNER FETCH---")
  console.log("GAS needed for start fetching (first call to claimWinOrDraw: " + await bet.getMinOraclizeGasCost.call())
  console.log("isFetchingStarted: " + await bet.isFetchingStarted.call())
  console.log("queryStatus: " + await bet.queryStatus.call())
  console.log("queryGoalsP1: " + await bet.queryGoalsP1.call())
  console.log("queryGoalsP2: " + await bet.queryGoalsP2.call())  
  console.log("matchFinished: " + await bet.matchFinished.call())
  console.log("fetchAttempt: " + await bet.fetchAttempt.call())
  console.log("isFetchFundingNeeded: " + await bet.isFetchFundingNeeded.call())
  
  console.log("timeBettingOpens: " + await bet.timeBettingOpens.call())
  console.log("timeBettingCloses: " + await bet.timeBettingCloses.call())
  console.log("timeMatchEnds: " + await bet.timeMatchEnds.call())
  console.log("timeSuggestConfirmEnds: " + await bet.timeSuggestConfirmEnds.call())
  console.log("test: " + await bet.test.call())

  console.log("goalsP1: " + await bet.goalsP1.call())
  console.log("goalsP2: " + await bet.goalsP2.call())
  console.log("goalsP1Fetched: " + await bet.goalsP1Fetched.call())
  console.log("goalsP2Fetched: " + await bet.goalsP2Fetched.call())
  console.log("winner: " + await bet.winner.call())

  //console.log("CONFIRM WINNER:" + await bet.confirmWinner(2, {from: owner}))
  console.log("\n---WINNER CONFIRM---")
  console.log("winnerConfirmed: " + await bet.winnerConfirmed.call())
  console.log("pool: " + await bet.pool.call())
  console.log("payoutPool: " + await bet.payoutPool.call())
  console.log("remainingPayoutPool: " + await bet.remainingPayoutPool.call())
  console.log("feeEarning: " + await bet.feeEarning.call())

  // console.log('before bet')
  // result = await bet.betOnPlayer1({from: owner, value: 2*tenthEther})
  // console.log(result)
  // console.log("----done")
  // result = await bet.betOnPlayer2({from: user1, value: 8*tenthEther})
  // console.log(result)
  // //result = await promisify(bet => bet.bet(1, {from: owner, value: tenthEther}))


  // bet.bet(1, {from: user1, value: tenthEther}).then(function(result) {
  //   console.log(result)
  //   // result.tx => transaction hash, string
  //   // result.logs => array of trigger events (1 item in this case)
  //   // result.receipt => receipt object
  // }).catch(function(err) {
  //   // Easily catch all errors along the whole execution.
  //   console.log("ERROR! " + err.message)
  // });


}

main().catch(console.error)
// transaction (writes) : meta.sendCoin(account_two, 10, {from: account_one})
// call (reads): meta.getBalance.call(account_one, {from: account_one})


// const MyContract = contract({
//   abi: ...,
//   unlinked_binary: ...,
//   address: ..., // optional
//   // many more
// })
//BetManager.setProvider(provider);



//console.log(result)
//console.log(result.receipt)
//console.log(result.tx)
//console.log(result.logs)








//console.log(result.receipt.gasUsed)

//estGas = betAddress.bet.estimateGas({from: owner, value: tenthEther})

// CAN USE web3 instance of Mist browser or Chrom+Metamask.
// Is there an injected web3 instance?
// if (typeof web3 !== 'undefined') {
//   App.web3Provider = web3.currentProvider;
// } else {
//   // If no injected web3 instance is detected, fall back to Ganache
//   App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
// }
// web3 = new Web3(App.web3Provider);


// const assert = require('assert')
// const chalk = require('chalk')
// const { finalizedBBK } = require('./bbk')
// const {
//   getEtherBalance,
//   getReceipt,
//   gasPrice,
//   bigZero,
//   testIsInRange,
//   getRandomBig
// } = require('./general')
// const BigNumber = require('bignumber.js')


//betManager = await BetManager.at(betManagerAddress)
//betManager = await BetManager.deployed()
//betManager.createBet()
//await result = betManager.test.call('Germany', 'Russia')
//console.log(result)

    // result.tx (string) - Transaction hash
    // result.logs (array) - Decoded events (logs)
    // result.receipt (object) - Transaction receipt



const setupContracts = async (owner) => {
  const betManager = await BetManager.deploy()
  console.log(betManager.address)

  const result = betManager.test('Germany', 'Russia')
  console.log(result)

  const balance = await web3.eth.getBalance(owner)
  console.log('owner ether balance:', balance)
  //bet.balanceOf(owner) .... that works?

  const bet = await betManager.createBet({from: owner})

  //var instance = MetaCoin.at("0x1234...");


  const watchBetAdded = betManager.BetAdded({}, { fromBlock: 0 }, (err, event) => {
    if (err) {
      console.error('This is strange ...', err)
      reject(err)
    }
    console.log(event)
    //if (event.transactionHash !== txid) return // these are not the txs you are looking for
    resolve(event.args.token) // the address of the token created
    watchBetAdded.stopWatching()
  })
}

// send ether to contract:
// instance.sendTransaction({...}).then(function(result) {
//   // Same transaction result object as above.
// });
// // OR:
// instance.send(web3.toWei(1, "ether")).then(function(result) {
//   // Same result object as above.
// });

const getEtherBalance = address => {
  return new Promise((resolve, reject) => {
    web3.eth.getBalance(address, (err, res) => {
      if (err) reject(err)

      resolve(res)
    })
  })
}

const getReceipt = txHash => {
  // seems that sometimes actual transaction is returned instead of txHash
  if (typeof txHash === 'object') {
    return txHash.receipt
  }
  return new Promise(function(resolve, reject) {
    web3.eth.getTransactionReceipt(txHash, (err, res) => {
      if (err) {
        reject(err)
      }

      resolve(res)
    })
  })
}

const getGasUsed = async txHash => {
  const receipt = await getReceipt(txHash)
  return receipt.gasUsed
}