<template>
  <div class="container" id="app">

    <div class="row">
      <img src="../static/img/ethercup.png" style="width: 100px;" />
      <h1>Ethercup</h1>
      <div style="margin-top: -20px;">14 JUNE - 15 JULY</div>
      <div style="margin-top: 5px; margin-bottom: 20px">
        <a href="https://github.com/ethercup/ethercup/blob/master/README.md" target="_blank">
          <i>How it works</i>
        </a>
      </div>
    </div>

    <div class="container">
      <hr>
    </div>

    <template v-if="(hasMetamask && isUsingCorrectNetwork)">
      <div id="personal" class="container">
        <b>Your Account:</b>
        <p v-if="isSignedInMetamask">
          Address: <span class="monospace">{{ getShortAddress(this.account) }}</span><br>
          Balance: <i>{{ this.balance }} ETH</i>
        </p>
        <p v-else class="warning">
          Please sign in Metamask<br>
          to see your account details
        </p>
        <hr>
      </div>

      <div v-if="info != ''" class="container warning info">
        {{ info }}
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
        <p class="warning metamask-issue">
          MetaMask browser plugin not found.<br>
          Please install MetaMask to proceed.
        </p>
        <a href="https://metamask.io" target="_blank">
          <img src="./assets/metamask.png" width="50%"/>
        </a>
      </template>
      <template v-else-if="!isUsingCorrectNetwork">
        <p class="warning metamask-issue">
          Currently, you are on the {{ getNetworkName(network) }}.<br>
          Please switch to the <b>{{ getNetworkName(correctNetwork) }}</b> in Metamask.
        </p>
      </template>
    </template>

    <!-- footer -->
    <div class="container footer">
      <hr>
      <p>
        GitHub: <a href="https://github.com/ethercup/ethercup" target="_blank">https://github.com/ethercup/ethercup</a><br>
        Built on Ethereum.<br>
        Built with Oraclize, Truffle, Web3, VueJS and football-data.org<br>
        <br>
        Contact:
        <a href="mailto:mailatethercup@gmail.com?Subject=Hi%20Ethercup" target="_top">mailatethercup@gmail.com</a>
        or
        <a href="https://www.reddit.com/user/ethercup" target="_blank">/u/ethercup</a>
        on reddit
      </p>
    </div>
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
      isUsingCorrectNetwork: true,
      hasMetamask: false,
      account: '',
      updateInterval: null,
      balance: 0,
      info: ''
    }
  },
  computed: {
    isSignedInMetamask () {
      return this.account != ''
    },
    correctNetwork () {
      console.log(process.env.ADDRESS_BET_REGISTRY)
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
        if (this.network != n) {
          this.network = n
          if (n == process.env.NETWORK_ID) {
            this.isUsingCorrectNetwork = true;
            if (this.account != '') {
              this.updateBalance()  
            }
          } else {
            this.isUsingCorrectNetwork = false;
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
    },
    getShortAddress(address) {
      if (address != undefined && address.length > 5) {
        return address.substring(0,6) + "..." + address.substring(address.length-4)  
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
/* skeleton override */
hr {
  margin-top: 1.5rem;
  margin-bottom: 2rem;
  border-width: 0;
  border-top: 2px solid black;
}
.monospace {
  font-family: monospace;
}
.gray {
  color: #bbb;
}
.success {
  color: rgb(111, 175, 38);
  font-style: italic;
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
  text-align: center;
}
.info {
  margin-bottom: 3rem;
}
.metamask-issue {
  font-size: 1.8rem;
  line-height: 3rem;
  margin: 50px 0px;
}
.footer {
  margin-top: 60px;
}
</style>
