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
var jsonBlobReg = require('../build/contracts/BetRegistry.json')
var jsonBlobLib = require('../build/contracts/oraclizeLib.json')
var betContract = TruffleContract(jsonBlob)
var betRegistryContract = TruffleContract(jsonBlobReg)
var oraclizeLib = TruffleContract(jsonBlobLib)
betContract.setProvider(provider)
betRegistryContract.setProvider(provider)
oraclizeLib.setProvider(provider)
betContract.defaults({
    gasPrice: 6e9,
    from: owner
})
betRegistryContract.defaults({
    gasPrice: 6e9,
    from: owner
})
fixTruffleContractCompatibilityIssue(betContract) // workaround. see https://github.com/trufflesuite/truffle-contract/issues/57
fixTruffleContractCompatibilityIssue(betRegistryContract)
fixTruffleContractCompatibilityIssue(oraclizeLib)

const INITIAL_FUND = 1e16 // in wei
const NOW = Number((new Date().getTime() / 1000).toFixed(0))
const MATCHES2 = [
    [0, '165069', 'Group A', 'Russia', 'Saudi Arabia', true, NOW+3600*5, 3600*24, 3600*24],
    [1, '165084', 'Group A', 'Egypt', 'Uruguay', true, NOW+3600*5, 3600, 3600*24],
    [2, '165083', 'Group B', 'Morocco', 'Iran', true, NOW+15*60, 3600, 3600*2],
    [3, '165076', 'Group B', 'Portugal', 'Spain', true, NOW+3600*5, 3600*24, 3600*24],
    [4, '165072', 'Group C', 'France', 'Australia', true, NOW, 3600*24, 3600*24],
    [5, '165073', 'Group D', 'Argentina', 'Iceland', true, NOW-10*7*24*3600, 3600*24, 3600*24],
    [6, '165071', 'Group C', 'Peru', 'Denmark', true, NOW-5*3600, 3600*24, 3600*24]
]

const MATCHES = [
    [7, '165071', 'Group C', 'Peru', 'Denmark', true, NOW-5*3600, 3600*24, 3600*24]
]

deployAndRegisterBet = (registry, betContract, params) => {
    // set initial bet fund used for fetching match results
    params.push({value: INITIAL_FUND})

    return betContract.new.apply(betContract, params).then((instance) => {
        console.log("Bet deployed: " + instance.address)
        return registry.addBet(instance.address)
    }).catch(err => {
        console.log("Error while deploying Bet contract")
        console.log(err)
    })
}

deployContracts = async (registryAddress) => {
    // Unlock owner account
    console.log('Unlock owner account: ' + await web3.eth.personal.unlockAccount(owner, 'test'))
    
    // deploy or init registry
    let registry
    if (registryAddress == null || registryAddress == '') {
        registry = await betRegistryContract.new.apply(betRegistryContract)
        console.log(' > Registry deployed: ' + registry.address)
    } else {
        registry = await betRegistryContract.at(registryAddress)
        console.log(' > Using Registry at: ' + registry.address)    
    }

    // deploy OraclizeLib
    var lib = await oraclizeLib.new.apply(oraclizeLib)
    console("OraclizeLib deployed!")
    console.log(lib)
    
    betContract.('oraclizeLib', lib.address)
    console.log("lib linked!!")
    // deploy bets and register them
    for (match of MATCHES) {
        console.log('...Deploying bet ' + match[0] + ' ...')
        await deployAndRegisterBet(registry, betContract, match)
        console.log(' > Bet ' + match[0] + ' registered!')
    }
}

deployContracts().catch(err => console.log(err))
