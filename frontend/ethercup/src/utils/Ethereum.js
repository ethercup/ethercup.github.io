import Web3 from 'web3'
import TruffleContract from 'truffle-contract'

const DEFAULT_GAS = 170000
const BET_GAS = 90000
const DEFAULT_GAS_PRICE = 6e9

export default {
  created () {
  },
  data () {
    return {
      web3: null,
      provider: null,
      bet: {
        contract: null,
        addresses: [],
        instances: []
      },
      betRegistry: {
        address: process.env.ADDRESS_BET_REGISTRY
      },
      isWaiting: false
    }
  },
  methods: {
    initWeb3 () {
      if (typeof(this.web3) !== 'undefined') {
        this.provider = web3.currentProvider
        this.web3 = new Web3(this.provider)
      } else {
        console.log('Please install the MetaMask browser plugin to proceed')
      }
    },
    getAccounts: function() {
      return this.web3.eth.getAccounts()
    },
    getBalance(account) {
      return this.web3.eth.getBalance(account)
    },
    getNetwork() {
      return this.web3.eth.net.getId()
    },
    getNetworkName (networkId) {
      switch (networkId) {
        case 1:
          return 'Main network'
        case 2:
          return 'Morden test network'
        case 3:
          return 'Ropsten test network'
        case 4:
          return 'Rinkeby test network'
        case 42:
          return 'Kovan test network'
        default:
          console.log('This is an unknown network.')
          return 'Unknown network'
      } 
    },
    getBetRegistryInstance (provider) {  
      let betRegistryArtifact = require('../../../../backend/build/contracts/BetRegistry.json')
      this.betRegistry.contract = TruffleContract(betRegistryArtifact)
      this.betRegistry.contract.setProvider(provider)
      return this.betRegistry.contract.at(this.betRegistry.address)
    },
    getBetContract (provider) {
      var betArtifact = require('../../../../backend/build/contracts/Bet.json')
      let contract = TruffleContract(betArtifact)
      contract.setProvider(provider)
      contract.defaults({
        gas: DEFAULT_GAS,
        gasPrice: DEFAULT_GAS_PRICE
      })
      return contract
    },
    getNumBets (registry) {
      return registry.nextIndex.call()
    },
    getBetAddress (registry, matchId) {
      return registry.betContracts.call(matchId)
    },
    getBetInstance (contract, addr) {
      return contract.at(addr)
    },
    claimWinOrDraw (betInstance, account) {
      return betInstance.claimWinOrDraw({
        from: account,
        gas: DEFAULT_GAS
      })
    }
  }
}