const BetJSON = require('../../backend/build/contracts/Bet.json')
const BetRegistryJSON = require('../../backend/build/contracts/BetRegistry.json').abi
const Artifactor = require('truffle-artifactor')
const artifactor = new Artifactor('./src/assets/contracts/');

buildContracts = async () => {
    await artifactor.save(BetJSON)
    await artifactor.save(BetRegistryJSON)
}
buildContracts().catch(err => {
    console.error(err)
})
//const BetContract = TruffleContract(BetJSON)
//const Web3 = require('web3')
//const fs = require('fs')

// const web3 = new Web3()

// const BetContract = new web3.eth.Contract(BetJSON)
// const BetRegistryContract = new web3.eth.Contract(BetRegistryJSON)
// const BetContract2 = TruffleContract(BetJSON)
// console.log(BetContract2)

// fs.writeFileSync('./src/assets/contracts/Bet.json', JSON.stringify(BetContract) , 'utf-8');
// fs.writeFileSync('./src/assets/contracts/Bet2.json', JSON.stringify(BetContract2) , 'utf-8');
// fs.writeFileSync('./src/assets/contracts/BetRegistry.json', JSON.stringify(BetRegistryContract) , 'utf-8');