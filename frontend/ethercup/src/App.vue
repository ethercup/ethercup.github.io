<template>
  <div id="app">
    <img src="./assets/logo.png">
    {{ this.account }}<br>
    {{ this.balance }}
    <Bets/>
  </div>
</template>

<script>
import Web3 from 'web3'
import TruffleContract from 'truffle-contract'
import Bets from './components/Bets'

export default {
  name: 'App',
  components: {
    Bets
  },
  data () {
    return {
      web3: null,
      provider: null,
      network: 0,
      betRegistry: null,
      bets: [],
      account: '',
      accountRefresh: null,
      balance: 0,
    }
  },
  mounted () {
    this.initWeb3()
    this.updateNetworkAndAccount()
    this.networkCheck()
  },
  methods: {
    initWeb3 () {
      if (typeof web3 === 'undefined') {
        console.error('web3 not detected...')
        return
      }
      if (web3) {
        // Use Mist/MetaMask's provider
        this.provider = web3.currentProvider
        web3 = new Web3(this.provider)
        
        var betRegistryArtifact = require('../../../backend/build/contracts/BetRegistry.json')
        var betRegistryContract = TruffleContract(betRegistryArtifact)
        betRegistryContract.setProvider(this.provider)
        this.betRegistry = betRegistryContract.at('0xbff77919292f804dbd4c5c072ccdd31858de44fa')

        var betArtifact = require('../../../backend/build/contracts/Bet.json')
        var betContract = TruffleContract(betArtifact)
        betContract.setProvider(this.provider)
        this.bets[0] = betContract.at('0x77ada3b6e85b7eb6b5f8f51cf958a62aabded2fa')
      
      }
    },
    updateBalance () {
      web3.eth.getBalance(this.account).then(b => {
        this.balance = Number(web3.utils.fromWei(b))
      })
    },
    updateNetworkAndAccount () {
      web3.eth.getAccounts().then(acc => this.account = acc[0])
      web3.eth.getAccounts().then(acc => console.log)
      
      var that = this
      this.accountInterval = setInterval(function() {
        web3.eth.getAccounts().then(acc => {
          if (acc[0] !== that.account) {
            that.account = acc[0]
            that.updateBalance()
          }
        })
        web3.eth.net.getId().then(n => {
          if (Number(n) !== that.network) {
            that.network = Number(n)
            that.updateBalance()
          }
        })
      }, 200);
    },
    networkCheck () {
      web3.eth.net.getId(function (err, netId) {
        console.log(netId)
        if (err) {
          console.log(err)
          return
        }
        switch (netId) {
          case 1:
            console.log('This is mainnet')
            break
          case 2:
            console.log('This is the deprecated Morden test network.')
            break
          case 3:
            console.log('This is the ropsten test network.')
            break
          case 4:
            console.log('This is the rinkeby test network.')
            break
          case 42:
            console.log('This is the kovan test network.')
            break
          default:
            console.log('This is an unknown network.')
        }
      })
    },
  },
  beforeDestroy () {
    clearInterval(this.accountInterval)
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
