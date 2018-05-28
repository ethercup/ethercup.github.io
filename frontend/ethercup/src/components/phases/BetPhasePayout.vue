<template>
  <div>
    <Announcement>
      <span style="color: rgb(111, 175, 38);">
        {{ getWinnerPhrase }}
      </span>
    </Announcement>

    <template v-if="(isMetamaskNetworkLoginReady && hasPayouts)">
      <Note>
        The match result is confirmed
        and payouts can be claimed now!
      </Note>
      <ActionClaimWinOrDraw
        v-bind:instance="instance"
      >
        Claim payout
      </ActionClaimWinOrDraw>
    </template>
    <template v-else>
      <template v-if="!isMetamaskNetworkLoginReady">
        <Warning>
          Metamask isn't ready.<br>
          Please log in Metamask and chose Main Ethereum network.
        </Warning>
      </template>
      <template v-else-if="!hasPayouts">
        <Warning>
          Your account has no payouts to claim.
        </Warning>
      </template>
    </template>

    <Times>
      <TimeTimeout>
        Payouts expire at<br>
        {{ getReadableDate(timeClaimsExpire) }}
      </TimeTimeout>
    </Times>
  </div>
</template>

<script>
  import { mapGetters } from 'vuex'
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import Note from './bases/Note.vue'
  import Warning from './bases/Warning.vue'
  import ActionClaimWinOrDraw from './bases/ActionClaimWinOrDraw.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'

  export default {
    name: 'BetPhasePayout',
    mixins: [Helpers],
    components: {
      Announcement, Note, Warning, ActionClaimWinOrDraw, Times, TimeTimeout
    },
    props: ['instance', 'timeClaimsExpire','hasPayouts', 'getWinnerPhrase'],
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