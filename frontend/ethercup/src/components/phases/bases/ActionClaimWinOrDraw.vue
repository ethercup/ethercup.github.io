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
        <button class="button button-primary" v-on:click="claimWinOrDraw()">
          <!-- slot value used for button text -->
          <slot></slot>
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
  props: ['instance'],
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
    claimWinOrDraw () {
      this.isLoading = true
      instance.claimWinOrDraw({
        from: this.account,
        gas: process.env.GAS_DEFAULT
      }).then(r => {
        this.$emit('claimed')
        this.success = 'Payouts claimed successfully!'
        this.isLoading = false
      })
      .catch(err => {
        this.error = 'Claiming payouts failed or rejected.'
        this.isLoading = false
      })
    }
  }
}
</script>

<style scoped>
button {
  width: 100%;
  position: relative;
}
</style>