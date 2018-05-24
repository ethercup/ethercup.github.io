<template>
  <div class="container" id="app">

    <h1>Ethercup</h1>

    <template v-if="(hasMetamask && isUsingCorrectNetwork)">
      <div id="personal" class="container">
        <b>Your Account:</b>
        <p v-if="isSignedInMetamask">
          Address: {{ this.account }}<br>
          Balance: <i>{{ this.balance }} ETH</i>
        </p>
        <p v-else class="warning">
          Please sign in Metamask<br>
          to see your account details
        </p>
      </div>

      <Bets
          v-bind:web3="web3"
          v-bind:provider="provider"
          v-bind:account="account"
          v-bind:balance="balance"
      />
    </template>
    <template v-else>
      <template v-if="!hasMetamask">
        <p class="warning no-metamask">
          MetaMask browser plugin not found.<br>
          Please install MetaMask to proceed.
        </p>
        <a href="https://metamask.io" target="_blank">
          <img src="./assets/metamask.png" width="50%"/>
        </a>
      </template>
      <template v-if="!isUsingCorrectNetwork">
        <p class="warning metamask-issue">
          Currently, you are on the {{ getNetworkName(network) }}.<br>
          Please switch to the <b>{{ getNetworkName(correctNetwork) }}</b> in Metamask.
        </p>
      </template>
    </template>
  </div>
</template>

<script>
import Web3 from 'web3'
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
      hasMetamask: false,
      account: '',
      updateInterval: null,
      balance: 0,
    }
  },
  computed: {
    isSignedInMetamask () {
      return this.account != ''
    },
    isUsingCorrectNetwork () {
      return this.networkId == process.env.NETWORK_ID
    },
    correctNetwork () {
      return process.env.NETWORK_ID
    }
  },
  created () {
    require('dotenv').config();
    this.initWeb3()
    this.updateNetworkAndAccount()
  },
  methods: {
    initWeb3 () {
      if (typeof web3 !== 'undefined') {
        this.provider = web3.currentProvider
        this.web3 = new Web3(this.provider)
        this.hasMetamask = true
      } else {
        console.log('Please install the MetaMask browser plugin to proceed')
      }
    },
    updateBalance () {
      this.web3.eth.getBalance(this.account).then(b => {
        this.balance = Number(this.web3.utils.fromWei(b)).toFixed(3)
      })
    },
    getAccount() {
      this.web3.eth.getAccounts().then(acc => {
        if (acc !== undefined && acc.length > 0 && acc[0] != this.account) {
          this.account = acc[0].toLowerCase()
          this.updateBalance()
        }
      })
    },
    getNetwork () {
      this.web3.eth.net.getId().then(n => {
        if (n != this.network) {
          this.network = n
          if (this.account != '') {
            this.updateBalance()  
          }
        }
      })
    },
    updateNetworkAndAccount () {
      var that = this
      this.updateInterval = setInterval(function() {
        that.getAccount()
        that.getNetwork()
      }, 200);
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
    }
  },
  beforeDestroy () {
    clearInterval(this.updateInterval)
  }
}
</script>

<style>
p {
  line-height: 2rem;
}
.gray {
  color: #bbb;
}
.warning {
  color: red;
  font-style: italic;
}
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
#personal {
  text-align: left;
}
.metamask-issue {
  font-size: 1.8rem;
  line-height: 3rem;
  margin: 50px 0px;
}
</style>
