<template>
  <div>
    <Announcement>
      Is the match over? If yes,<br>
      let's start fetching the match result.
    </Announcement>

    <template v-if="isMetamaskNetworkLoginReady">
      <Note>
        Click the Activate button to start fetching now. Depending
        on the external data provider, this may take a while...
      </Note>
      <ActionClaimWinOrDraw
        v-bind:instance="instance"
      >
        Activate
      </ActionClaimWinOrDraw>
    </template>
    <template v-else>
      <Warning>
        Metamask isn't ready.<br>
        Please log in Metamask and chose Main Ethereum network.
      </Warning>
    </template>

    <Times>
      <TimeTimeout>
        Match result must be fetched and confirmed until<br>
        {{ getReadableDate(timeSuggestConfirmEnds) }}
      </TimeTimeout>
    </Times>
  </div>
</template>

<script>
  import { mapGetters} from 'vuex'
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import Note from './bases/Note.vue'
  import ActionClaimWinOrDraw from './bases/ActionClaimWinOrDraw.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'

  export default {
    name: 'BetPhaseShouldStartFetch',
    mixins: [Helpers],
    components: {
      Announcement, Note, ActionClaimWinOrDraw, Times, TimeTimeout
    },
    props: ['instance', 'matchId', 'account', 'timeSuggestConfirmEnds'],
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
button {
  width: 100%;
  position: relative;
}
</style>