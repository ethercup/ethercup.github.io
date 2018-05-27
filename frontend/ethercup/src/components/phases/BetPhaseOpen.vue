<template>
  <BaseBetPhase>

    <template slot="header">
      Place your bets now!
    </template>

    <template slot="main">
      <template v-if="isMetamaskNetworkLoginReady">
        <Note>
          Click on a country's flag to<br>
          select your favorite team.
        </Note>
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
          <div class="two columns" style="line-height: 4rem; text-align: left;">
            ETH
          </div>
        </div>
        <div class="row">
          <div class="eight columns offset-by-two">
            <button class="button-primary" v-on:click="placeBet()">
              Bet
              <img v-if="isWaiting" src="../../assets/spinner.gif" class="spinner" />
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
        Betting closes at {{ getReadableDate(timeBettingCloses) }}
      </Time>
      <Time class="matchstart">
        Match begins at {{ getReadableDate(timeMatchStarts) }}
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
    name: 'BetPhaseOpen',
    mixins: [Helpers],
    components: {
      BaseBetPhase, Note, Time
    },
    props: ['timeBettingCloses', 'timeMatchStarts', 'isMetamaskNetworkLoginReady'],
    data () {
      return {
        warning: '',
        success: '',
        betAmount: '',
        isWaiting: false
      }
    }
  }

</script>

<style scoped>
.timeout {
  color: orange;
}
.matchstart {
  color: rgb(111, 175, 38);
}
input {
  width: 100%;
  margin-bottom: 0.5rem;
}
button {
  width: 100%;
  position: relative;
}
</style>