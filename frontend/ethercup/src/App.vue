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
          v-bind:account="account"
          v-bind:balance="balance"
          v-bind:isMetamaskNetworkLoginReady="isMetamaskNetworkLoginReady"
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
          Currently, you are on the {{ getNetworkName(currentNetwork) }}.<br>
          Please switch to the <b>{{ getNetworkName(targetNetwork) }}</b> in Metamask.
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
import Helpers from './utils/Helpers.js'
import { mapGetters, mapState } from 'vuex'
import Bets from './components/Bets'

export default {
  name: 'App',
  components: {
    Bets
  },
  mixins: [Helpers],
  data () {
    return {
      updateInterval: null,
      info: ''
    }
  },
  computed: {
    getTargetNetwork () {
      return process.env.NETWORK_ID
    },
    ...mapState({
      web3: state => state.web3,
      currentNetwork: 'currentNetwork',
      targetNetwork: 'targetNetwork',
      account: 'account',
      balance: 'balance'
    }),
    ...mapGetters({
      hasMetamask: 'hasMetamask',
      isUsingCorrectNetwork: 'isUsingCorrectNetwork',
      isSignedInMetamask: 'isSignedInMetamask',
      isMetamaskNetworkLoginReady: 'isMetamaskNetworkLoginReady'
    })
  },
  created () {
    require('dotenv').config();
    this.initStore()
    this.updateNetworkAndAccount()
  },
  methods: {
    initStore() {
      this.$store.commit('initWeb3')
      this.$store.commit('setTargetNetwork', process.env.NETWORK_ID)
      this.$store.commit('setRegistryAddress', process.env.ADDRESS_BET_REGISTRY)

    },
    updateBalance () {
      if(this.web3.utils.isAddress(this.account)) {
        this.getBalance(this.account).then(b => {
          this.balance = Number(this.web3.utils.fromWei(b)).toFixed(3)
        })
      }
    },
    updateAccount() {
      this.getAccounts().then(accounts => {
        if (accounts !== undefined && accounts.length > 0 && accounts[0].toLowerCase() != this.account) {
          this.account = accounts[0].toLowerCase()
          this.updateBalance()
        }
      })
    },
    updateNetwork () {
      this.getNetwork().then(n => {
        if (this.network != n) {
          this.network = n
          if (this.correctNetwork == n && this.account != '') {
            this.isUsingCorrectNetwork = true
              this.updateBalance()   
          }
        }
      })
    },
    updateNetworkAndAccount () {
      var that = this
      this.updateInterval = setInterval(function() {
        that.$store.dispatch('updateAccount')
        that.$store.dispatch('updateCurrentNetwork')
      }, 200)
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
