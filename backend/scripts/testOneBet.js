var Web3 = require('web3')
var TruffleContract = require("truffle-contract")
var HDWalletProvider = require('truffle-hdwallet-provider');
var fs = require('fs')

const mnemonic = fs.readFileSync('./mnemonic.txt', 'utf8', function (err, data) {
  if (err) throw err;
  console.log(data);
});

const provider = new HDWalletProvider(mnemonic, "http://localhost:8545", 0, 5)
const web3 = new Web3(provider)

const owner = '0x4f3e7B7900e1352a43EA1a6aA8fc7F1FC03EfAc9'.toLowerCase() //acc1

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

var jsonBlob = require('../build/contracts/Bet.json')
var betContract = TruffleContract(jsonBlob)
betContract.setProvider(provider)
betContract.defaults({
    gasPrice: 6e9,
    from: owner
})

fixTruffleContractCompatibilityIssue(betContract) // workaround. see https://github.com/trufflesuite/truffle-contract/issues/57




testBet = async () => {
    var bet = await betContract.at('0x6d95d2ea7724218a9b60833f428dce93f08a034d')
    
    // Unlock owner account
    //console.log('Unlock owner account: ' + await web3.eth.personal.unlockAccount(owner, 'test'))
    console.log('...Starting test')
    bet.fetchOnRequest({from: owner, value: 1e16}).then(r => {
        console.log("Call successful")
    }).catch(err => {
        console.log("Error while test Bet contract")
        console.log(err)
    })
}

testBet().catch(err => console.log(err))
