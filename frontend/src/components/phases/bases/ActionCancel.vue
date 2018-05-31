<template>
  <div class="cancel">
    <Warning v-if="error != ''">
    {{ error }}
    </Warning>
    <Success v-if="success != ''">
      {{ success }}
    </Success>
    <button class="button-cancel" v-on:click="cancel()">
      <span v-if="!isLoading">&#10005;</span>
      <img v-if="isLoading" src="../../../assets/spinner.gif" class="spinner" />
    </button>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Success from './Success.vue'
import Warning from './Warning.vue'

export default {
  name: 'ActionCancel',
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
    cancel: function() {
      this.success = ''
      this.error = ''

      this.isLoading = true;
      this.instance.cancel({
        from: this.account,
        gas: process.env.GAS_DEFAULT
      })
      .then(r => {
        this.isLoading = false;
        this.success = 'Cancelled!'
        this.$emit('success')
      })
      .catch(err => {
        this.isLoading = false;
        this.error = 'Failed.'
      })
    }
  }
}
</script>

<style scoped>
.cancel {
  position: absolute;
  margin: 5px;
  left: 0px;
  bottom: 0px;
  line-height: 0rem;
}
.button-cancel {
  width: 50px;
  margin-bottom: 0px;
  padding: 0px;
  background-color: red;
}
.button-cancel:hover {
  background-color: rgb(163, 6, 6);
}
</style>