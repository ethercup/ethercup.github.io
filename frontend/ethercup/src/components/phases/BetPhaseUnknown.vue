<template>
  <div>
    <Announcement>
      Unknown bet status :()
    </Announcement>

    <Note>
      Please contact the admin!
    </Note>

    <Times>
      <TimeMatchstart>
        Planned match begin at {{ getReadableDate(timeMatchStarts) }}
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
    name: 'BetPhaseUnknown',
    mixins: [Helpers],
    components: {
      Announcement, Note, Times, TimeMatchstart
    },
    props: ['timeMatchStarts']
  }

</script>

<style scoped>
</style>