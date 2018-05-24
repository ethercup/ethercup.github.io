<template>
  <div class="container" id="app">

    <h1>Ethercup</h1>

    <template v-if="hasMetamask">
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
      <p class="warning no-metamask">
        MetaMask browser plugin not found.<br>
        Please install MetaMask to proceed.
      </p>
      <a href="https://metamask.io" target="_blank">
        <img src="./assets/metamask.png" width="50%"/>
      </a>
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
      accountRefresh: null,
      balance: 0,
    }
  },
  computed: {
    isSignedInMetamask () {
      return this.account != ''
    }
  },
  created () {
    this.initWeb3()
    this.updateNetworkAndAccount()
    this.networkCheck()
  },
  methods: {
    initWeb3 () {
      if (typeof web3 !== 'undefined') {
        this.provider = web3.currentProvider
        this.web3 = new Web3(this.provider)
        this.hasMetamask = true
      } else {
        console.log('No web3? You should consider trying MetaMask!')
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
          this.account = acc[0]
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
      this.accountInterval = setInterval(function() {
        that.getAccount()
        that.getNetwork()
      }, 200);
    },
    networkCheck () {
      this.web3.eth.net.getId(function (err, netId) {
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
.no-metamask {
  font-size: 1.8rem;
  line-height: 3rem;
  margin: 50px 0px;
}
</style>
