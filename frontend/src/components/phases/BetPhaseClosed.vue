<template>
  <div>
    <Announcement>
      Betting is closed.<br>
      Match is beginning shortly...
    </Announcement>

    <Times>
      <TimeMatchstart>
        Match begins at 
            {{ getReadableDate(timeMatchStarts) }}
      </TimeMatchstart>
    </Times>
  </div>
</template>

<script>
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import Times from './bases/Times.vue'
  import TimeMatchstart from './bases/TimeMatchstart.vue'

  export default {
    name: 'BetPhaseClosed',
    mixins: [Helpers],
    components: {
      Announcement, Times, TimeMatchstart
    },
    props: ['timeMatchStarts']
  }

</script>

<style scoped>
</style>