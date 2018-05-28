<template>
  <div>
    <Announcement>
      Match result is currently being fetched...
    </Announcement>

    <Times>
      <TimeTimeout>
        Match result must be confirmed until<br>
        {{ getReadableDate(timeSuggestConfirmEnds) }}
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
    name: 'BetPhaseFetching',
    mixins: [Helpers],
    components: {
      Announcement, Times, TimeTimeout
    },
    props: ['timeSuggestConfirmEnds']
  }

</script>

<style scoped>
</style>