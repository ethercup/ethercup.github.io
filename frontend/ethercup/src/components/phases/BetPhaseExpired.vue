<template>
  <div>
    <Announcement>
      {{ getWinnerPhrase }}
    </Announcement>

    <Times>
      <TimeTimeout>
        Payouts expired at<br>
            {{ getReadableDate(timeClaimsExpire) }}
      </TimeTimeout>
    </Times>
  </div>
</template>

<script>
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'

  export default {
    name: 'BetPhaseExpired',
    mixins: [Helpers],
    components: {
      Announcement, Times, TimeTimeout
    },
    props: ['getWinnerPhrase']
  }

</script>

<style scoped>
</style>