<template>
  <BaseBetPhase>

    <template slot="header">
      <span style="color: rgb(111, 175, 38);">
        {{ getWinnerPhrase }}
      </span>
    </template>

    <template slot="main">
      <template v-if="isMetamaskNetworkLoginReady">
        <Note>
          The match result is confirmed
          and payouts can be claimed now!
        </Note>
        <Warning v-if="warning != ''">
          {{ warning }}
        </Warning>
        <Success v-if="success != ''">
          {{ success }}
        </Success>
        <div class="row" v-if="hasPayouts">
          <div class="eight columns offset-by-two">
            <button class="button button-primary" v-on:click="claimWinOrDraw()">
              Claim payout
              <img v-if="isWaiting" src="../../assets/spinner.gif" class="spinner" />
            </button>
          </div>
        </div>
        <div v-else>
          You don't have any payouts to claim.
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
        Payouts expire at<br>
        {{ getReadableDate(timeClaimsExpire) }}
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
    name: 'BetPhasePayout',
    mixins: [Helpers],
    components: {
      BaseBetPhase, Note, Time
    },
    props: ['timeClaimsExpire', 'isMetamaskNetworkLoginReady', 'hasPayouts', 'getWinnerPhrase'],
    data () {
      return {
        warning: '',
        success: '',
        isWaiting: false,
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