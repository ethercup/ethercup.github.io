var Web3 = require('web3')
var contract = require('truffle-contract')

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


const provider = new Web3.providers.HttpProvider("http://localhost:8545")
const web3 = new Web3(provider)

const betAddress = '0x772a3c0287289426174edec227e4aa42a1aff539'
const owner = '0x4f3e7B7900e1352a43EA1a6aA8fc7F1FC03EfAc9' //acc1
const user1 = '0xCE1834593259431E36b3F7b68655A88d8Bf6ffca' //acc2
const tenthEther = 100000000000000000 // wei

web3.eth.personal.unlockAccount(owner, "mohoffde91", 0)
.then((response) => {
    console.log(response);
  }).catch((error) => {
    console.log(error);
  });
web3.eth.personal.unlockAccount(user1, "mohoffde91", 0)
.then((response) => {
    console.log(response);
  }).catch((error) => {
    console.log(error);
  });

var contract = require("truffle-contract")
var jsonBlob = require('../build/contracts/Bet.json')
var betContract = contract(jsonBlob)
betContract.setProvider(provider)
fixTruffleContractCompatibilityIssue(betContract) // workaround. see https://github.com/trufflesuite/truffle-contract/issues/57


const promisify = (inner) =>
  new Promise((resolve, reject) =>
    inner((err, res) => {
      if (err) { reject(err) }

      resolve(res);
    })
  );




var bet = betContract.at(betAddress)

//result = bet.bet(1, {from: owner, value: tenthEther})
//result = await promisify(bet => bet.bet(1, {from: owner, value: tenthEther}))


bet.bet(1, {from: user1, value: tenthEther}).then(function(result) {
  console.log(result)
  // result.tx => transaction hash, string
  // result.logs => array of trigger events (1 item in this case)
  // result.receipt => receipt object
}).catch(function(err) {
  // Easily catch all errors along the whole execution.
  console.log("ERROR! " + err.message)
});

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