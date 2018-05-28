<template>
  <div>
    <div class="container">
      <p>
        Matches live: {{ numBets }}/64<br>
        <label for="checkbox" style="display: inline; font-weight: 400;">Hide finished matches:</label>
        <input type="checkbox" id="checkbox" v-model="hideFinishedMatches">
      </p>
      
    </div>

    <!-- Check if hiderFinishedMatches works -->
    <!--<p>TEAM, BETTINGOPEN, LAST X, NEXT X</p>-->
    <ul v-if="numBets > 0">
      <Bet
        v-for="n in numBets" :key="n"
        v-bind:matchId="n-1"
        v-bind:registryInstance="registryInstance"
        v-bind:hideFinishedMatches="hideFinishedMatches"
      />
    </ul>
    <div v-else class="gray" style="font-style: italic;">
      No bets found...
    </div>
  </div>
</template>



<script>
import Bet from './Bet'
import { mapState } from 'vuex'

export default {
  name: 'Bets',
  components: {
    Bet
  },
  // import numBets here from vuex
  data () {
    return {
      registryInstance: null,
      hideFinishedMatches: false,
    }
  },
  computed: {
    ...mapState({
      numBets: state => state.bets.num
    })
  },
  methods: {
  },
  created () {
    this.$store.dispatch('getRegistry').then((instance) => {
      // workaround since registry instance can't be stored in vuex for some reason (commit-function calls invalid instance function?)
      this.registryInstance = instance
      this.$store.dispatch('updateNumBets', instance)
    })
    this.$store.commit('initBetContract')
  },
}
</script>



