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

const INITIAL_FUND = 1e16 // in wei
const NOW = Number((new Date().getTime() / 1000).toFixed(0))

const MATCH = [
    0, '165071', 'Group C', 'Peru', 'Denmark', true,
    NOW-5*3600, 3600*24, 3600*24,
    {value: INITIAL_FUND}
]

deployBet = async () => {
    // Unlock owner account
    //console.log('Unlock owner account: ' + await web3.eth.personal.unlockAccount(owner, 'test'))
    
    // deploy bets and register them
    console.log('...Deploying bet ' + MATCH[0] + ' ...')
    betContract.new.apply(betContract, MATCH).then((instance) => {
        console.log("Bet deployed: " + instance.address)
    }).catch(err => {
        console.log("Error while deploying Bet contract")
        console.log(err)
    })
}

deployBet().catch(err => console.log(err))
