<template>
  <div>
    <Announcement>
      Is the match over? If yes,<br>
      let's start fetching the match result.
    </Announcement>

    <template v-if="isMetamaskNetworkLoginReady">
      <Note>
        Click the Activate button to start fetching. Depending
        on the external data provider, this may take a while...
      </Note>
      <ActionClaimWinOrDraw
        :instance="instance"
        :caller="0"
        @claimed="reemit()"
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
  import Warning from './bases/Warning.vue'
  import ActionClaimWinOrDraw from './bases/ActionClaimWinOrDraw.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'

  export default {
    name: 'BetPhaseShouldStartFetch',
    mixins: [Helpers],
    components: {
      Announcement, Note, Warning, ActionClaimWinOrDraw, Times, TimeTimeout
    },
    props: ['instance', 'timeSuggestConfirmEnds'],
    computed: {
      ...mapGetters({
        isMetamaskNetworkLoginReady: 'isMetamaskNetworkLoginReady'
      })
    },
    methods: {
      reemit () {
        this.$emit('claimed')
      }
    }
  }

</script>

<style scoped>
</style>