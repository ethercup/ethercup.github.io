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
        <button v-on:click="claimRefund()">
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

export default {
  name: 'ActionClaimRefund',
  components: {
    Success, Warning
  },
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
    claimRefund () {
      this.success = ''
      this.error = ''
      this.isLoading = true

      this.instance.claimRefund({
        from: this.account,
        gas: process.env.GAS_DEFAULT
      }).then(r => {
        this.$emit('claimed')
        this.success = 'Refund claimed successfully!'
        this.isLoading = false
      })
      .catch(err => {
        console.log(err)
        this.error = 'Claiming refund failed or rejected.'
        this.isLoading = false
      })
    }
  }
}
</script>

<style scoped>
</style>