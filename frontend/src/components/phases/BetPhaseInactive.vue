<template>
  <div>
    <Announcement>
      Bet is inactive.
    </Announcement>

    <Note>
      It is too early to place bets. Please come back later.
    </Note>

    <Times>
      <!-- TODO: make this not timematchstart but maybe TimeGreen, TimeGray, TimeRed -->
      <TimeMatchstart>
        Bet opens at {{ getReadableDate(timeBettingOpens) }}
      </TimeMatchstart>
      <TimeMatchstart>
        Match begins at {{ getReadableDate(timeMatchStarts) }}
      </TimeMatchstart>
    </Times>
  </div>
</template>

<script>
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import Note from './bases/Note.vue'
  import Times from './bases/Times.vue'
  import TimeMatchstart from './bases/TimeMatchstart.vue'

  export default {
    name: 'BetPhaseInactive',
    mixins: [Helpers],
    components: {
      Announcement, Note, Times, TimeMatchstart
    },
    props: ['timeBettingOpens', 'timeMatchStarts']
  }

</script>

<style scoped>
</style>