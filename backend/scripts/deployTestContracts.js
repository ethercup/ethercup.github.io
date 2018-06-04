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

var jsonTemplate = require('../build/contracts/BetTemplate.json')
var jsonFactory = require('../build/contracts/BetFactory.json')
var jsonRegistry = require('../build/contracts/BetRegistry.json')
var template = TruffleContract(jsonTemplate)
var factory = TruffleContract(jsonFactory)
var registry = TruffleContract(jsonRegistry)
template.setProvider(provider)
factory.setProvider(provider)
registry.setProvider(provider)
template.defaults({ gasPrice: 6e9, from: owner })
factory.defaults({ gasPrice: 6e9, from: owner })
registry.defaults({ gasPrice: 6e9, from: owner })

fixTruffleContractCompatibilityIssue(template) // workaround. see https://github.com/trufflesuite/truffle-contract/issues/57
fixTruffleContractCompatibilityIssue(factory)
fixTruffleContractCompatibilityIssue(registry)

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

// deployAndRegisterBet = (registry, betContract, params) => {
//     // set initial bet fund used for fetching match results
//     params.push({value: INITIAL_FUND})

//     return betContract.new.apply(betContract, params).then((instance) => {
//         console.log("Bet deployed: " + instance.address)
//         return registry.addBet(instance.address)
//     }).catch(err => {
//         console.log("Error while deploying Bet contract")
//         console.log(err)
//     })
// }

deployContracts = async (registryAddress) => {
    // Unlock owner account
    //console.log('Unlock owner account: ' + await web3.eth.personal.unlockAccount(owner, 'test'))
    
    // deploy or init registry
    let registryI
    if (registryAddress == null || registryAddress == '') {
        registryI = await registry.new.apply(registry)
        console.log(' > Registry deployed: ' + registryI.address)
    } else {
        registryI = await registry.at(registryAddress)
        console.log(' > Using Registry at: ' + registryI.address)    
    }

    // deploy factory
    factoryI = await factory.new.apply(factory)
    console.log(' > BetFactory deployed at ' + factoryI.address)

    // deploy template
    templateI = await template.new.apply(template)
    console.log(' > BetTemplate deployed at ' + templateI.address)
    
    // deploy bet
    var result = await factoryI.createBet2(templateI.address, 0)
    console.log(' > Bet deployed!! Result')
    console.log(result)
    const betAddress = result.logs[0].address
    console.log('new address: ' + betAddress)

    // init bet
    template = TruffleContract(jsonTemplate)
    template.setProvider(provider)
    template.defaults({ gasPrice: 6e9, from: owner })
    fixTruffleContractCompatibilityIssue(template)
    betI = await template.at('0xABB2C85C1DF2a65a9d9Be20456e39Acf2e92746C'.toLowerCase())
    betI.initBet(
       3, '165076', 'Group B', 'Portugal', 'Spain',
       true, NOW+3600, {value: INITIAL_FUND})
    .then(result => {
        console.log('BetI initialized! Result:')
        console.log(result)
    }).catch(err => {
        console.log(err)
    })
    

    // // register bet address
    // var registerResult = await registryI.addBet(betAddress)
    // console.log('Bet (' + betAddress + ') registered!')

    // deploy bets 
    // for (match of MATCHES) {
    //     console.log('...Deploying bet ' + match[0] + ' ...')
    //     await deployAndRegisterBet(registry, betContract, match)
    //     console.log(' > Bet ' + match[0] + ' registered!')
    // }
}

deployContracts().catch(err => console.log(err))
