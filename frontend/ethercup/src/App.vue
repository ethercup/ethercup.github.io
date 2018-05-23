<template>
  <div class="container" id="app">

    <h1>Ethercup</h1>

    <div id="personal" class="container">
      <b>Your Account:</b>
      <p>
        Address: {{ this.account }}<br>
        Balance: <span style="font-style: italic">{{ this.balance }} ETH</span>
      </p>
    </div>

    <Bets
        v-bind:web3="web3"
        v-bind:provider="provider"
        v-bind:account="account"
        v-bind:balance="balance"
    />

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
      account: '',
      accountRefresh: null,
      balance: 0,
    }
  },
  created () {
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
        this.web3 = new Web3(this.provider)
      }
    },
    updateBalance () {
      this.web3.eth.getBalance(this.account).then(b => {
        this.balance = Number(this.web3.utils.fromWei(b))
      })
    },
    getAccount() {
      this.web3.eth.getAccounts().then(acc => {
        if (acc[0] != this.account) {
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
</style>
