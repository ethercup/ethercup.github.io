<template>
  <div class="container" id="app">

    <div class="row">
      <img id="logo" src="../static/img/ethercup.png" />
      <h1>Ethercup</h1>
      <div id="subheadline">14 JUNE - 15 JULY</div>
      <div id="howitworks">
        <a href="https://github.com/ethercup/ethercup/blob/master/README.md" target="_blank">
          <i>How it works</i>
        </a>
      </div>
    </div>

    <div class="container">
      <hr>
    </div>

    <template v-if="(hasMetamask && isUsingCorrectNetwork && !isNetworkLoading)">
      <div class="container">
        <b>Your Account:</b>
        <p v-if="isSignedInMetamask">
          Address:
            <!--<span class="monospace">{{ getShortAddress(this.account) }}</span>-->
            <template v-if="account != '0'">
              <span class="monospace">{{ getShortAddress(this.account) }}</span>
            </template>
            <template v-else>
              <i>loading...</i>
            </template>
            <br>
          Balance:
            <i>{{ this.balance }} ETH</i>
        </p>
        <p v-else class="warning">
          Please sign in Metamask<br>
          to see your account details
        </p>
        <hr>
      </div>
      
      <Bets
          v-bind:account="account"
          v-bind:balance="balance"
          v-bind:isMetamaskNetworkLoginReady="isMetamaskNetworkLoginReady"
      />
      
    </template>
    <template v-else>
      <template v-if="!hasMetamask">
        <p class="big warning">
          MetaMask browser plugin not found.<br>
          Please install MetaMask to proceed.
        </p>
        <a href="https://metamask.io" target="_blank">
          <img src="./assets/metamask.png" id="metamask"/>
        </a>
      </template>
      <template v-else-if="isNetworkLoading">
        <p class="big italic">
          Loading...
        </p>
      </template>
      <template v-else-if="!isUsingCorrectNetwork">
        <p class="big warning">
          Currently, you are on the {{ getNetworkName(currentNetwork) }}.<br>
          Please switch to the <b>{{ getNetworkName(targetNetwork) }}</b> in Metamask.
        </p>
      </template>
    </template>

    <!-- footer -->
    <div id="footer" class="container">
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
      updateInterval: null
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
      isNetworkLoading: 'isNetworkLoading',
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
    updateNetworkAndAccount () {
      var that = this
      this.updateInterval = setInterval(function() {
        that.$store.dispatch('checkWeb3')
        that.$store.dispatch('updateCurrentNetwork')
        that.$store.dispatch('updateAccount')
      }, 500)
    }
  },
  beforeDestroy () {
    clearInterval(this.updateInterval)
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
#logo {
  width: 100px;
}
#subheadline {
  margin-top: -20px;
}
#howitworks {
  margin-top: 5px;
  margin-bottom: 20px;
}
#metamask {
  width: 50%;
}
#footer {
  margin-top: 60px;
}
</style>
