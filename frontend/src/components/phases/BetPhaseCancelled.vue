<template>
  <div>
    <Announcement>
      <span class="red">Bet is cancelled!</span>
    </Announcement>

    <template v-if="(isMetamaskNetworkLoginReady && hasPayouts)">
      <Note>
        The match is cancelled but you can<br>
        claim your refunds now!
      </Note>
      <ActionClaimRefund
        :instance="instance"
        @claimed="reemit()">
        Claim refund
      </ActionClaimRefund>
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
          Your account has no refunds to claim.
        </Warning>
      </template>
    </template>

    <Times>
      <TimeMatchstart>
        Planned match begin at {{ getReadableDate(timeMatchStarts) }}
      </TimeMatchstart>
    </Times>
  </div>
</template>

<script>
  import { mapGetters} from 'vuex'
  import Helpers from '../../utils/Helpers.js'
  import ActionClaimRefund from './bases/ActionClaimRefund.vue'
  import Announcement from './bases/Announcement.vue'
  import Note from './bases/Note.vue'
  import Warning from './bases/Warning.vue'
  import Times from './bases/Times.vue'
  import TimeMatchstart from './bases/TimeMatchstart.vue'

  export default {
    name: 'BetPhaseCancelled',
    mixins: [Helpers],
    components: {
      Announcement, Note, Warning, ActionClaimRefund, Times, TimeMatchstart
    },
    props: ['instance', 'timeMatchStarts', 'hasPayouts'],
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