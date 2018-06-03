<template>
  <div>
    <Announcement>
      <span class="green">
        {{ getWinnerPhrase }}
      </span>
    </Announcement>

    <template v-if="(isMetamaskNetworkLoginReady && hasPayouts)">
      <Note>
        The match result is confirmed
        and payouts can be claimed now!
      </Note>
      <ActionClaimWinOrDraw
        :instance="instance"
        :caller="2"
        @claimed="reemit()"
      >
        Claim payout
      </ActionClaimWinOrDraw>
    </template>
    <template v-else>
      <template v-if="!isMetamaskNetworkLoginReady">
        <Warning>
          Metamask isn't ready.<br>
          Please log in Metamask and choose Main Ethereum network.
        </Warning>
      </template>
      <template v-else><!---if="!hasPayouts">-->
        <Note>
          Your account has no payouts to claim.
        </Note>
      </template>
    </template>

    <Times>
      <TimeTimeout>
        Payouts expire at {{ getReadableDate(timeClaimsExpire) }}
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
    },
    methods: {
      reemit () {
        // Do not reemit here. Otherwise UI changes quickly to "Your account has no bets to claim".
        // Give user feedback that claim was successful.
        //this.$emit('claimed')
      }
    }
  }

</script>

<style scoped>
</style>