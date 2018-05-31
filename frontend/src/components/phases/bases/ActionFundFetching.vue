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
        <button v-on:click="fundFetching()">
          <slot></slot> {{ toEther(fundingNeeded).toFixed(3) }} {{ unit }}
          <img v-if="isLoading" src="../../../assets/spinner.gif" class="spinner" />
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Helpers from '../../../utils/Helpers.js'
import Success from './Success.vue'
import Warning from './Warning.vue'

export default {
  name: 'ActionBet',
  components: {
    Success, Warning
  },
  mixins: [Helpers],
  props: ['instance', 'fundingNeeded', 'caller'],
  data () {
    return {
      success: '',
      error: '',
      isLoading: false
    }
  },
  computed: {
    ...mapState({
      account: state => state.account
    })
  },
  methods: {
    fundFetching () {
      this.success = ''
      this.error = ''
      this.isLoading = true

      this.instance.fundFetching({
        from: this.account,
        value: this.fundingNeeded,
        gas: process.env.GAS_FUND
      }).then(r => {
        this.$emit('funded')
        this.success = 'Sending funds succeeded! Thanks for your support!'
        this.isLoading = false
      })
      .catch(err => {
        this.error = 'Funding failed or rejected.'
        this.isLoading = false
      })
    }
  }
}
</script>

<style scoped>
</style>