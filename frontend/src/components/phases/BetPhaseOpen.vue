<template>
  <div>
    <Announcement class="green">
      Place your bets now!
    </Announcement>

    <template v-if="isMetamaskNetworkLoginReady">
      <Note>
        Click on a country's flag to<br>
        select your favorite team.
      </Note>
      <ActionBet
        :instance="instance"
        :p1="p1"
        :p2="p2"
        :betTeam="betTeam"
        @bet-placed="reemit()"/>
    </template>
    <template v-else>
      <Warning>
        Metamask isn't ready.<br>
        Please log in Metamask and choose Main Ethereum network.
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
  import Note from './bases/Note.vue'
  import Warning from './bases/Warning.vue'
  import ActionBet from './bases/ActionBet.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'
  import TimeMatchstart from './bases/TimeMatchstart.vue'

  export default {
    name: 'BetPhaseOpen',
    mixins: [Helpers],
    components: {
      Announcement, Note, Warning, ActionBet, Times, TimeTimeout, TimeMatchstart
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
    },
    methods: {
      // workaround to pass events from child (ActionBet.vue) to its grandparent (Bet.vue). Alternatives: register event listeners, event bus
      reemit () {
        this.$emit('bet-placed')
      }
    }
  }

</script>

<style scoped>
</style>