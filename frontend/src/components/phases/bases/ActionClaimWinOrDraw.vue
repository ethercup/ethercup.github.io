<template>
  <div>
    <Warning v-if="error != ''">
      {{ error }}
    </Warning>
    <Success v-if="success != ''">
      {{ success }}
    </Success>
    <div class="row">
      <div class="eight columns offset-by-two">
        <button v-on:click="claimWinOrDraw()">
          <slot></slot>
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

const START_FETCHING = 0
const TOO_LATE_CONFIRM = 1
const PAYOUT = 2

export default {
  name: 'ActionBet',
  components: {
    Success, Warning
  },
  props: ['instance', 'caller'],
  data () {
    return {
      success: '',
      error: '',
      isLoading: false,
      messages: {
        // TODO: How to do this nice in vue/js?
        success: {
          0: 'Started fetching successfully! Thanks!',
          1: 'Activating smart contract succeeded!',
          2: 'Payouts claimed successfully!'
        },
        error: {
          0: 'Starting of fetching failed or rejected.',
          1: 'Activating smart contract failed or rejected.',
          2: 'Claiming payouts failed or rejected.'
        }
      }
    }
  },
  computed: {
    ...mapState({
      account: state => state.account
    })
  },
  methods: {
    claimWinOrDraw () {
      this.success = ''
      this.error = ''
      this.isLoading = true

      this.instance.claimWinOrDraw({
        from: this.account,
        gas: process.env.GAS_DEFAULT
      }).then(r => {
        this.$emit('claimed')
        this.success = this.messages.success[this.caller]
        this.isLoading = false
      })
      .catch(err => {
        this.error = this.messages.error[this.caller]
        this.isLoading = false
      })
    }
  }
}
</script>

<style scoped>
</style>