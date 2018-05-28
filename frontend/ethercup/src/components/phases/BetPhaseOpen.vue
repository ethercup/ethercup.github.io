<template>
  <div>
    <Announcement>
      Place your bets now!
    </Announcement>

  ` <template v-if="isMetamaskNetworkLoginReady">
      <Note>
        Click on a country's flag to<br>
        select your favorite team.
      </Note>
      <ActionBet
        v-bind:instance="instance"
        v-bind:p1="p1"
        v-bind:p2="p2"
        v-bind:betTeam="betTeam"/>
    </template>
    <template v-else>
      <Warning>
        Metamask isn't ready.<br>
        Please log in Metamask and chose Main Ethereum network.
      </Warning>
    </template>

    <Times>
      <TimeTimeout>
        Betting closes at {{ getReadableDate(timeBettingCloses) }}
      </TimeTimeout>
      <TimeMatchstart>
        Match begins at {{ getReadableDate(timeMatchStarts) }}
      </TimeMatchstart>
    </Times>
  </div>
</template>

<script>
  import { mapGetters } from 'vuex'
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import ActionBet from './bases/ActionBet.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'
  import TimeMatchstart from './bases/TimeMatchstart.vue'

  export default {
    name: 'BetPhaseOpen',
    mixins: [Helpers],
    components: {
      Announcement, ActionBet, Times, TimeTimeout, TimeMatchstart
    },
    props: ['instance', 'p1', 'p2', 'betTeam', 'timeBettingCloses', 'timeMatchStarts'],
    data () {
      return {
        warning: '',
        success: '',
        betAmount: '',
        isWaiting: false
      }
    },
    computed: {
      ...mapGetters({
        isMetamaskNetworkLoginReady: 'isMetamaskNetworkLoginReady'
      })
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