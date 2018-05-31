<template>
  <div>
    <Announcement>
      Match result is currently being fetched...
    </Announcement>

    <Note>
      If the external data provider made the result public, this should take minutes. If not, retries are scheduled and the waiting time goes up to hours.
    </Note>

    <Times>
      <TimeTimeout>
        Match result must be fetched and confirmed until<br>
        {{ getReadableDate(timeSuggestConfirmEnds) }}
      </TimeTimeout>
    </Times>
  </div>
</template>

<script>
  import Helpers from '../../utils/Helpers.js'
  import Announcement from './bases/Announcement.vue'
  import Note from './bases/Note.vue'
  import Times from './bases/Times.vue'
  import TimeTimeout from './bases/TimeTimeout.vue'

  export default {
    name: 'BetPhaseFetching',
    mixins: [Helpers],
    components: {
      Announcement, Note, Times, TimeTimeout
    },
    props: ['timeSuggestConfirmEnds']
  }

</script>

<style scoped>
</style>