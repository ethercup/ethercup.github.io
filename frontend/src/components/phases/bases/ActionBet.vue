<template>
  <div>
    <Warning v-if="error != ''">
      {{ error }}
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
        <button v-on:click="placeBet()">
          Bet
          <img v-if="isLoading" src="../../../assets/spinner.gif" class="spinner" />
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Success from './Success.vue'
import Warning from './Warning.vue'

export default {
  name: 'ActionBet',
  components: {
    Success, Warning
  },
  props: ['instance', 'p1', 'p2', 'betTeam'],
  data () {
    return {
      success: '',
      error: '',
      isLoading: false,

      betAmount: '',
    }
  },
  computed: {
    ...mapState({
      web3: state => state.web3,
      account: state => state.account
    })
  },
  methods: {
    placeBet: function() {
      this.success = ''
      this.error = ''

      if (this.betTeam != this.p1 && this.betTeam != this.p2) {
        this.error = 'Please select your favorite team first.'
        return
      }

      let wei
      let weiBN
      try {
        wei = this.web3.utils.toWei(this.betAmount)
        weiBN = this.web3.utils.toBN(wei)
      } catch(err) {
        this.error = 'Please enter a valid amount of Ether first.'
        return
      }
      if (wei.charAt(0) === '-') {
        this.error = 'Negative Ether not allowed.'
        return
      }
      if (weiBN < 1e15) {
        this.error = 'Minimum bet is 0.001 Ether.'
        return
      }

      console.log(wei)

      this.error = ''
      this.isLoading = true;
      if (this.betTeam == this.p1) {
        this.instance.betOnPlayer1({
          from: this.account,
          gas: process.env.GAS_BET,
          value: wei
        })
        .then(r => {
          this.isLoading = false;
          this.success = 'Bet placed successfully!'
          this.$emit('bet-placed')
        })
        .catch(err => {
          this.isLoading = false;
          this.error = 'Transaction failed or rejected.'
        })
      } else if (this.betTeam == this.p2) {
        this.instance.betOnPlayer2({
          from: this.account,
          gas: process.env.GAS_BET,
          value: wei
        })
        .then(r => {
          this.isLoading = false;
          this.success = 'Bet placed successfully!'
          this.$emit('bet-placed')
        })
        .catch(err => {
          this.isLoading = false;
          this.error = 'Transaction failed or rejected'
        })  
      }
    }
  }
}
</script>

<style scoped>
</style>