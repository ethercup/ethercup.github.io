import Vue from 'vue'
import Vuex from 'vuex'
import Web3 from 'web3'
import TruffleContract from 'truffle-contract'

//const BetContract = require('./assets/contracts/Bet.json')
//const BetRegistryContract = require('./assets/contracts/BetRegistry.json')
var Bet


Vue.use(Vuex)

// root state object.
// each Vuex instance is just a single state tree.
const state = {
  web3: null,
  provider: '',
  account: '',
  balance: 0,
  currentNetwork: 0,
  targetNetwork: 0,
  registry: {
    address: '',
    //contract: require('./assets/contracts/BetRegistry.json')
  },
  bets: {
    num: 0,
    //contract: require('./assets/contracts/Bet.json'),
    addresses: [],
    bets: null
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
    state.account = account
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
    state.bets.bets = Array(num).fill({})
  },
  setBetAddress (state, payload) {
    state.bets.addresses[payload.matchId] = payload.address
  },
  setRawStatus (state, payload) {
    state.bets.bets[payload.matchId].rawStatus = payload.data
  },
  setMatchContext (state, payload) {
    state.bets.bets[payload.matchId].matchContext = payload.data
  },
  setP1 (state, payload) {
    state.bets.bets[payload.matchId].p1 = payload.data
  },
  setP2 (state, payload) {
    state.bets.bets[payload.matchId].p2 = payload.data
  },
  setMatchFinished (state, payload) {
    state.bets.bets[payload.matchId].matchFinished = payload.data
  },
  setMyBetsP1 (state, payload) {
    state.bets.bets[payload.matchId].myBetsP1 = payload.data
  },
  setMyBetsP2 (state, payload) {
    state.bets.bets[payload.matchId].myBetsP2 = payload.data
  },
  setTotalP1 (state, payload) {
    state.bets.bets[payload.matchId].totalP1 = payload.data
  },
  setTotalP2 (state, payload) {
    state.bets.bets[payload.matchId].totalP2 = payload.data
  },
  setNumBetsP1 (state, payload) {
    state.bets.bets[payload.matchId].numBetsP1 = payload.data
  },
  setNumBetsP2 (state, payload) {
    state.bets.bets[payload.matchId].numBetsP2 = payload.data
  },
  setTimeBettingOpens (state, payload) {
    state.bets.bets[payload.matchId].timeBettingOpens = payload.data
  },
  setTimeBettingCloses (state, payload) {
    state.bets.bets[payload.matchId].timeBettingCloses = payload.data
  },
  setTimeFetchConfirmEnds (state, payload) {
    state.bets.bets[payload.matchId].timeFetchConfirmEnds = payload.data
  },
  setTimeClaimsExpire (state, payload) {
    state.bets.bets[payload.matchId].timeClaimsExpire = payload.data
  },
  setIsFetchingStarted (state, payload) {
    state.bets.bets[payload.matchId].isFetchingStarted = payload.data
  },
  setIsWinnerFetched (state, payload) {
    state.bets.bets[payload.matchId].isWinnerFetched = payload.data
  },
  setIsWinnerConfirmed (state, payload) {
    state.bets.bets[payload.matchId].isWinnerConfirmed = payload.data
  },
  setRawWinner (state, payload) {
    state.bets.bets[payload.matchId].rawWinner = payload.data
  },
  setFundingNeeded (state, payload) {
    state.bets.bets[payload.matchId].fundingNeeded = payload.data
  }
}

// actions are functions that cause side effects and can involve
// asynchronous operations.
const actions = {
  getStatus: async (context) => {
    console.log(context.state.bets.contract.methods)
    context.state.bets.contract.methods.status.call().then(s => {
        this.rawStatus = s
    })
  },
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
      if (accounts !== undefined &&
          accounts.length > 0 &&
          accounts[0].toLowerCase() != context.state.account)
      {
          context.commit('setAccount', accounts[0].toLowerCase())
          context.dispatch('updateBalance')
      }
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
  },
  initBetContract: async (context) => {
    Bet = TruffleContract(require('../../backend/build/contracts/Bet.json'))
    //console.log(artifact)
    Bet.setProvider(state.provider)
    Bet.setNetwork(process.env.NETWORK_ID)
    Bet.address = '0xdaa2122d6a3a1e9fe9348c61de1648c0e5e86eee'
    Bet.detectNetwork()
    //Bet.setNetwork(42)
    //console.log('111 ' + Bet.network_id)
    //console.log('2222 ' + Bet.networks[Bet.network_id])
    //console.log('now calling matchContext.call')
    Bet = Bet.at('0xdaa2122d6a3a1e9fe9348c61de1648c0e5e86eee')
    Bet.matchContext.call().then(r => {console.log(r)}).catch(err => {console.log(err)})
  },
  updateContractState: async (context, matchId) => {
    context.dispatch('updateContractBetState', matchId)

    context.dispatch('updateRawStatus', matchId)
    context.dispatch('updateMatchContext', matchId)
    context.dispatch('updateP1', matchId)
    context.dispatch('updateP2', matchId)
    context.dispatch('updateMatchFinished', matchId)
    context.dispatch('updateTimeBettingOpens', matchId)
    context.dispatch('updateTimeBettingCloses', matchId)
    context.dispatch('updateTimeFetchConfirmEnds', matchId)
    context.dispatch('updateTimeClaimsExpire', matchId)
    context.dispatch('updateIsFetchingStarted', matchId)
    context.dispatch('updateIsWinnerFetched', matchId)
    context.dispatch('updateIsWinnerConfirmed', matchId)
    context.dispatch('updateRawWinner', matchId)
    context.dispatch('updateFundingNeeded', matchId)
  },
  updateContractBetState: async (context, matchId) => {
    context.dispatch('updateMyBetsP1', matchId)
    context.dispatch('updateMyBetsP2', matchId)
    context.dispatch('updateTotalP1', matchId)
    context.dispatch('updateTotalP2', matchId)
    context.dispatch('updateNumBetsP1', matchId)
    context.dispatch('updateNumBetsP2', matchId)
  },
  updateRawStatus: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setRawStatus', {
      matchId: matchId,
      data: await Bet.status.call()
    })
  },
  updateMatchContext: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setMatchContext', {
      matchId: matchId,
      data: await Bet.matchContext.call()
    })
  },
  updateP1: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setP1', {
      matchId: matchId,
      data: await Bet.p1.call()
    })
  },
  updateP2: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setP2', {
      matchId: matchId,
      data: await Bet.p2.call()
    })
  },
  updateMatchFinished: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setMatchFinished', {
      matchId: matchId,
      data: await Bet.matchFinished.call()
    })
  },
  updateMyBetsP1: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setMyBetsP1', {
      matchId: matchId,
      data: (await Bet.betsPlayer1.call(context.state.account)).toString()
    })
  },
  updateMyBetsP2: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setMyBetsP2', {
      matchId: matchId,
      data: (await Bet.betsPlayer2.call(context.state.account)).toString()
    })
  },
  updateTotalP1: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setTotalP1', {
      matchId: matchId,
      data: (await Bet.totalPlayer1.call()).toString()
    })
  },
  updateTotalP2: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setTotalP2', {
      matchId: matchId,
      data: (await Bet.totalPlayer2.call()).toString()
    })
  },
  updateNumBetsP1: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setNumBetsP1', {
      matchId: matchId,
      data: Number(await Bet.numBetsPlayer1.call())
    })
  },
  updateNumBetsP2: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setNumBetsP2', {
      matchId: matchId,
      data: Number(await Bet.numBetsPlayer2.call())
    })
  },
  updateTimeBettingOpens: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setTimeBettingOpens', {
      matchId: matchId,
      data: Number(await Bet.timeBettingOpens.call())
    })
  },
  updateTimeBettingCloses: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setTimeBettingCloses', {
      matchId: matchId,
      data: Number(await Bet.timeBettingCloses.call())
    })
  },
  updateTimeFetchConfirmEnds: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setTimeFetchConfirmEnds', {
      matchId: matchId,
      data: Number(await Bet.timeSuggestConfirmEnds.call())
    })
  },
  updateTimeClaimsExpire: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setTimeClaimsExpire', {
      matchId: matchId,
      data: Number(await Bet.timeClaimsExpire.call())
    })
  },
  updateIsFetchingStarted: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setIsFetchingStarted', {
      matchId: matchId,
      data: await Bet.isFetchingStarted.call()
    })
  },
  updateIsWinnerFetched: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setIsWinnerFetched', {
      matchId: matchId,
      data: await Bet.winnerSuggested.call()
    })
  },
  updateIsWinnerConfirmed: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setIsWinnerConfirmed', {
      matchId: matchId,
      data: await Bet.winnerConfirmed.call()
    })
  },
  updateRawWinner: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    context.commit('setRawWinner', {
      matchId: matchId,
      data: Number(await Bet.winner.call())
    })
  },
  updateFundingNeeded: async (context, matchId) => {
    Bet.address = context.state.bets.addresses[matchId]
    Bet.fundingNeeded.call().then(r => {
      context.commit('setFundingNeeded', {
        matchId: matchId,
        data: String(r)
      })
    }).catch(err => {
      console.warn("getFundingNeeded behaves unexpectedly: " + err)
    })
  },
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
  isUsingCorrectNetwork: state => {
    return state.currentNetwork == state.targetNetwork
  },
  isMetamaskNetworkLoginReady: (state, getters) => {
    return getters.hasMetamask &&
      getters.isSignedInMetamask &&
      getters.isUsingCorrectNetwork
  },
  matchContext: (state) => (matchId) => {
    return state.bets.bets[matchId].matchContext
  },
  p1: (state) => (matchId) => {
    return state.bets.bets[matchId].p1
  },
  p2: (state) => (matchId) => {
    return state.bets.bets[matchId].p2
  },
  myBetsP1: (state) => (matchId) => {
    return state.bets.bets[matchId].myBetsP1
  },
  myBetsP2: (state) => (matchId) => {
    return state.bets.bets[matchId].myBetsP2
  },
  totalP1: (state) => (matchId) => {
    return state.bets.bets[matchId].totalP1
  },
  totalP2: (state) => (matchId) => {
    return state.bets.bets[matchId].totalP2
  },
  numBetsP1: (state) => (matchId) => {
    return state.bets.bets[matchId].numBetsP1
  },
  numBetsP2: (state) => (matchId) => {
    return state.bets.bets[matchId].numBetsP2
  },
  timeBettingOpens: (state) => (matchId) => {
    return state.bets.bets[matchId].timeBettingOpens
  },
  timeBettingCloses: (state) => (matchId) => {
    return state.bets.bets[matchId].timeBettingCloses
  },
  timeFetchConfirmEnds: (state) => (matchId) => {
    return state.bets.bets[matchId].timeFetchConfirmEnds
  },
  timeClaimsExpire: (state) => (matchId) => {
    return state.bets.bets[matchId].timeClaimsExpire
  },
  isFetchingStarted: (state) => (matchId) => {
    return state.bets.bets[matchId].isFetchingStarted
  },
  isWinnerFetched: (state) => (matchId) => {
    return state.bets.bets[matchId].isWinnerFetched
  },
  isWinnerConfirmed: (state) => (matchId) => {
    return state.bets.bets[matchId].isWinnerConfirmed
  },
  fundingNeeded: (state) => (matchId) => {
    return state.bets.bets[matchId].fundingNeeded
  },
}

export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations
})