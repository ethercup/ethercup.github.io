<template>
  <BaseBetPhase>

    <template slot="header">
      Is the match over? If yes,<br>
      let's start fetching the match result.
    </template>

    <template slot="main">
      <template v-if="isMetamaskNetworkLoginReady">
        <Note>
          Click the Activate button to start fetching now. Depending
          on the external data provider, this may take a while...
        </Note>
        <Warning v-if="warning != ''">
          {{ warning }}
        </Warning>
        <Success v-if="success != ''">
          {{ success }}
        </Success>
        <div class="row">
          <div class="eight columns offset-by-two">
            <button class="button button-primary" v-on:click="activate()">
              Activate
              <img v-if="isLoading" src="../../assets/spinner.gif" class="spinner" />
            </button>
          </div>
        </div>
      </template>
      <template v-else>
        <Warning>
          Metamask isn't ready.<br>
          Please log in Metamask and chose Main Ethereum network.
        </Warning>
      </template>
    </template>

    <template slot="times">
      <Time class="timeout">
        Match result must be fetched and confirmed until<br>
        {{ getReadableDate(timeSuggestConfirmEnds) }}
      </Time>
    </template>

  </BaseBetPhase>
</template>

<script>
  import Helpers from '../../utils/Helpers.js'
  import BaseBetPhase from './BaseBetPhase.vue'
  import Note from '../bases/Note.vue'
  import Time from '../bases/Time.vue'

  export default {
    name: 'BetPhaseShouldStartFetch',
    mixins: [Helpers],
    components: {
      BaseBetPhase, Note, Time
    },
    props: ['matchId', 'account', 'timeSuggestConfirmEnds', 'isMetamaskNetworkLoginReady'],
    data () {
      return {
        warning: '',
        success: '',
        isLoading: false
      }
    },
    methods: {
      activate () {
        this.isLoading = true
        console.log(this.bet.instances)
        this.claimWinOrDraw(this.matchId, this.account).then(r => {
          console.log("RESUUUULT")
          this.getContractState()
          this.success = 'Payouts claimed successfully!'
          this.isLoading = false
        })
        .catch(err => {
          this.warning = 'Claiming payouts failed or rejected.'
          this.isLoading = false
        })
      }
    }
  }

</script>

<style scoped>
.timeout {
  color: orange;
}
button {
  width: 100%;
  position: relative;
}
</style>