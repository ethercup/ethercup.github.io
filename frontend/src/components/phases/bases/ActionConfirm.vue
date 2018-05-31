<template>
  <div class="confirm">
    <span class="gray">Confirm:</span>
    <br>
    <input type="radio" id="p1" value="1" v-model="pickedWinner">
    <label for="p1">{{ p1 }} (P1)</label>
    <br>
    <input type="radio" id="p2" value="2" v-model="pickedWinner">
    <label for="p2">{{ p2 }} (P2)</label>
    <br>
    <input type="radio" id="draw" value="3" v-model="pickedWinner">
    <label for="draw">Draw</label>
    <br>
    <span v-if="pickedWinner != ''" class="gray">Picked: {{ pickedWinner }}</span>

    <Warning v-if="error != ''">
      {{ error }}
    </Warning>
    <Success v-if="success != ''">
      {{ success }}
    </Success>
    <button class="button-primary" v-on:click="confirmWinner()">
      <span v-if="!isLoading">&#10004;</span>
      <img v-if="isLoading" src="../../../assets/spinner.gif" class="spinner" />
    </button>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import Success from './Success.vue'
import Warning from './Warning.vue'

export default {
  name: 'ActionConfirm',
  components: {
    Success, Warning
  },
  props: ['instance', 'p1', 'p2'],
  data () {
    return {
      success: '',
      error: '',
      isLoading: false,

      pickedWinner: ''
    }
  },
  computed: {
    ...mapState({
      account: state => state.account
    })
  },
  methods: {
    confirmWinner: function() {
      this.success = ''
      this.error = ''

      if (this.pickedWinner == '') {
        this.error = 'Choose a result first.'
        return
      }

      this.isLoading = true;
      this.instance.confirmWinner(
        Number(this.pickedWinner),
        {
          from: this.account,
          gas: process.env.GAS_DEFAULT
        }
      )
      .then(r => {
        this.isLoading = false;
        this.success = 'Confirmed!'
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
.confirm {
  text-align: right;
  position: absolute;
  margin: 5px;
  right: 0px;
  bottom: 0px;
}
input {
  margin-bottom: 0px;
}
.button-confirm {
  width: 50px;
  margin-bottom: 0px;
  padding: 0px;
  background-color: rgb(40, 65, 255);
}
.button-confirm:hover {
  background-color: rgb(36, 53, 181);
}
</style>