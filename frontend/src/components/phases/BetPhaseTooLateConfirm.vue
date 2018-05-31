<template>
  <div>
    <Announcement>
      Unfortunately, the admin did not confirm<br>
      the match result in time.
    </Announcement>

    <template v-if="isMetamaskNetworkLoginReady">
      <Note>
        Feel free to activate the smart contract<br>
        so that you can claim your refund.
      </Note>
      <ActionClaimWinOrDraw
        :instance="instance"
        :caller="1"
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
        Confirmation of match result was due at<br>
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
    name: 'BetPhaseTooLateConfirm',
    mixins: [Helpers],
    components: {
      Announcement, Note, ActionClaimWinOrDraw, Times, TimeTimeout
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