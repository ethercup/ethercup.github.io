<template>
  <div>
    <Announcement>
      The smart contract ran out of funds<br>
      for fetching the match result.
    </Announcement>

    <template v-if="isMetamaskNetworkLoginReady">
      <Note>
        Click the Fund button to fund and start fetching of the match result.
      </Note>
      <ActionFundFetching
        :instance="instance"
        :fundingNeeded="fundingNeeded"
        @funded="reemit()"
      >
        Fund
      </ActionFundFetching>
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
        {{ getReadableDate(timeFetchConfirmEnds) }}
      </TimeTimeout>
    </Times>
  </div>
</template>

<script>
  import { mapGetters} from 'vuex'
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import Note from './bases/Note.vue'
  import ActionFundFetching from './bases/ActionFundFetching.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'

  export default {
    name: 'BetPhaseFundingNeeded',
    mixins: [Helpers],
    components: {
      Announcement, Note, ActionFundFetching, Times, TimeTimeout
    },
    props: ['instance', 'timeFetchConfirmEnds', 'fundingNeeded'],
    computed: {
      ...mapGetters({
        isMetamaskNetworkLoginReady: 'isMetamaskNetworkLoginReady'
      })
    },
    methods: {
      reemit () {
        this.$emit('funded')
      }
    }
  }

</script>

<style scoped>
</style>