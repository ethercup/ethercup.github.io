var Web3 = require('web3')
var contract = require('truffle-contract')
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

const GAS_PRICE = 6e9

const betRegistryAddress = '0x9540465c237EfB0C45a27741a845Ecb1558b878B'
const idToReplace = 0
const newAddress = '0x94750fd410d863d9bee95a5cbe358e630575c004'

const owner = '0x4f3e7B7900e1352a43EA1a6aA8fc7F1FC03EfAc9'.toLowerCase() //acc1

async function main() {
  const provider = new HDWalletProvider(mnemonic, "http://localhost:8545", 0, 5)
  const web3 = new Web3(provider)
  const tenthEther = 1e17 // wei

  console.log(await web3.eth.personal.unlockAccount(owner, 'test'))

  var jsonBlobReg = require('../build/contracts/BetRegistry.json')
  var betRegistryContract = contract(jsonBlobReg)
  betRegistryContract.setProvider(provider)
  betRegistryContract.defaults({
    gasPrice: GAS_PRICE,
  })
  fixTruffleContractCompatibilityIssue(betRegistryContract)
  
  var bet = betContract.at(betAddress)
  var betRegistry = betRegistryContract.at(betRegistryAddress)

  betRegistry.replaceBet(
    idToReplace,
    newAddress,
    {from: owner})
  .then(() => {
    console.log('BetRegistry: Index ' + id + ' replaced with address ' + newAddress)
  }
  .catch(err => {
    console.log('ERROR while replacing bet: ' + err)
  })

}


main().catch(console.error)