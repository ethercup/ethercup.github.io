<template>
  <div>
    <Announcement>
      Match result was successfully fetched<br>
      and now has to be confirmed. Looks like...<br>
      <span class="green">{{ getWinnerPhrase }}</span>
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
    name: 'BetPhaseWaitForConfirm',
    mixins: [Helpers],
    components: {
      Announcement, Times, TimeTimeout
    },
    props: ['timeSuggestConfirmEnds', 'getWinnerPhrase']
  }

</script>

<style scoped>
.green {
  color: rgb(111, 175, 38);
}
</style>