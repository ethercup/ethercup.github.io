import Vue from 'vue'
import Vuex from 'vuex'
import Web3 from 'web3'
import TruffleContract from 'truffle-contract'

Vue.use(Vuex)

// root state object.
// each Vuex instance is just a single state tree.
const state = {
  web3: null,
  provider: '',
  account: '0',
  balance: 0,
  currentNetwork: -1, // -1: loading
  targetNetwork: 0,
  registry: {
    address: '',
    contract: null,
    instance: null,
  },
  bets: {
    num: 0,
    contract: null,
    instances: [],
    addresses: []
  }
}


const mutations = {
  // used with store.commit('increment')
  // state always first argument, n is payload
  initWeb3 (state) {
    if (typeof(window.web3) !== 'undefined') {
      state.provider = window.web3.currentProvider
      state.web3 = new Web3(state.provider)
    } else {
      console.error('Please install the MetaMask browser plugin to proceed')
    }
  },
  setCurrentNetwork (state, network) {
    state.currentNetwork = network
  },
  setTargetNetwork (state, network) {
    state.targetNetwork = network
  },
  setAccount (state, account) {
    state.account = account.toLowerCase() 
  },
  setBalance (state, balance) {
    state.balance = balance
  },
  setRegistryAddress (state, address) {
    state.registry.address = address 
  },
  setRegistryContract (state, contract) {
    state.registry.contract = contract
  },
  setRegistryInstance (state, instance) {
    state.registry.instance = instance
  },
  setNumBets (state, num) {
    state.bets.num = num
  },
  initBetContract (state) {
    let betArtifact = require('../../backend/build/contracts/Bet.json')
    state.bets.contract = TruffleContract(betArtifact)
    state.bets.contract.setProvider(state.provider)
    state.bets.contract.defaults({
      gas: process.env.GAS_DEFAULT,
      gasPrice: process.env.GASPRICE_DEFAULT
    })
  },
}

// actions are functions that cause side effects and can involve
// asynchronous operations.
const actions = {
  getRegistry: async (context) => {
    let registryArtifact = require('../../backend/build/contracts/BetRegistry.json')
    let contract = TruffleContract(registryArtifact)
    contract.setProvider(context.state.provider)
    context.commit('setRegistryContract', contract)

    return new Promise(function(resolve, reject) {
      context.state.registry.contract.at(context.state.registry.address).then(function (instance) {
        // gives invalid RPC reponse. Does commit function call a function on instance object that latter doesn't accept?
        //context.commit('setRegistryInstance', instance)
        resolve(instance)
      })
    })
  },
  checkWeb3 (context) {
    if (typeof(window.web3) !== 'undefined') {
      return
    } else {
      context.commit('initWeb')
    }
  },
  updateCurrentNetwork (context) {
    context.state.web3.eth.net.getId().then(network => {
      if (context.state.currentNetwork != network) {
        context.commit('setCurrentNetwork', network)  
      }
    }).catch(err => {
      console.warn("Failed to read current network from Metamask.")
    })
  },
  updateAccount (context) {
    context.state.web3.eth.getAccounts().then(accounts => {
      if (accounts !== undefined && accounts.length > 0) {
        if(context.state.account != accounts[0].toLowerCase()) {
          context.commit('setAccount', accounts[0])
          context.dispatch('updateBalance')
        }
      } else {
        context.commit('setAccount', '')
      }
    }).catch(err => {
      console.warn('Failed to read account')
      context.commit('setAccount', '')
    })
  },
  updateBalance (context) {
    if(context.state.web3.utils.isAddress(context.state.account)) {
      context.state.web3.eth.getBalance(context.state.account).then(balance => {
          context.state.balance = Number(context.state.web3.utils.fromWei(balance)).toFixed(3)
      }).catch(err => {
        console.warn("Failed to read account balance.")
      })
    }
  },
  updateNumBets (context, registry) {
    registry.nextIndex.call().then(num => {
      context.commit('setNumBets', Number(num))
    })
  }
}

// getters are functions
const getters = {
  getWeb3: state => state.web3,
  hasMetamask: state => {
    return state.web3 !== 'undefined'
  },
  isSignedInMetamask: state => {
    return state.account != ''
  },
  isNetworkLoading: state => {
    return state.currentNetwork == -1
  },
  isUsingCorrectNetwork: state => {
    return state.currentNetwork == state.targetNetwork
  },
  isMetamaskNetworkLoginReady: (state, getters) => {
    return getters.hasMetamask &&
      getters.isSignedInMetamask &&
      getters.isUsingCorrectNetwork &&
      !getters.isNetworkLoading
  }
}

export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations
})