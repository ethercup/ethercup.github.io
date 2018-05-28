<template>
  <div>
    <Warning v-if="warning != ''">
      {{ warning }}
    </Warning>
    <Success v-if="success != ''">
      {{ success }}
    </Success>
    <div class="row">
      <div class="six columns offset-by-two">
        <input v-model="betAmount" type="number" step="0.1" min="0" placeholder="Your bet">
      </div>
      <div class="two columns unit">
        ETH
      </div>
    </div>
    <div class="row">
      <div class="eight columns offset-by-two">
        <button class="button-primary" v-on:click="placeBet()">
          Bet
          <img v-if="isLoading" src="../../../assets/spinner.gif" class="spinner" />
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Success from '../bases/Success.vue'
import Warning from '../bases/Warning.vue'

export default {
  name: 'ActionBet',
  props: ['instance', 'p1', 'p2', 'betTeam'],
  data () {
    return {
      success: '',
      error: '',
      isLoading: false,

      betAmount: 0
    }
  },
  computed: {
    ...mapState({
      account: state => state.account
    })
  },
  methods: {
    placeBet: function() {
      this.success = ''
      this.warning = ''

      if (this.betTeam != this.p1 && this.betTeam != this.p2) {
        this.warning = 'Please select your favorite team first.'
        return
      }

      let wei
      let weiBN
      try {
        wei = this.$store.web3.utils.toWei(this.betAmount)
        weiBN = this.$store.web3.utils.toBN(wei)
      } catch(err) {
        this.warning = 'Please enter a valid amount of Ether first.'
        return
      }
      if (wei.charAt(0) === '-') {
        this.warning = 'Negative Ether not allowed.'
        return
      }
      if (weiBN < 1e15) {
        this.warning = 'Minimum bet is 0.001 Ether.'
        return
      }

      console.log(wei)

      this.warning = ''
      this.isLoading = true;
      if (this.betTeam == this.p1) {
        console.log("lets bet on p1")
        this.instance.betOnPlayer1({
          from: this.account,
          gas: process.env.GAS_BET,
          value: wei
        })
        .then(r => {
          this.isLoading = false;
          this.success = 'Bet placed successfully!'
          this.$emit('bet-placed')
          console.log("event bet-placed emitted")
          // Tx hash: r.tx
        })
        .catch(err => {
          this.isLoading = false;
          this.warning = 'Transaction failed or rejected.'
        })
      } else if (this.betTeam == this.p2) {
        console.log("lets bet on p2")
        this.instance.betOnPlayer2({
          from: this.account,
          gas: process.env.GAS_BET,
          value: wei
        })
        .then(r => {
          this.isLoading = false;
          this.success = 'Bet placed successfully!'
          this.$emit('bet-placed')
          console.log("event bet-placed emitted")
          //Tx hash: r.tx
        })
        .catch(err => {
          this.isLoading = false;
          this.warning = 'Transaction failed or rejected'
        })  
      }
    }
  }
}
</script>

<style scoped>
button {
  width: 100%;
  position: relative;
}
.unit {
  line-height: 4rem;
  text-align: left;
}
</style>