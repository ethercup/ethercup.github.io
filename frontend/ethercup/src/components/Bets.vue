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
        v-bind:registry="registry"
        v-bind:contract="contract"
        v-bind:matchId="n-1"
        v-bind:account="account"
        v-bind:balance="balance"
        v-bind:hideFinishedMatches="hideFinishedMatches"
        v-bind:isMetamaskNetworkLoginReady="isMetamaskNetworkLoginReady"
      />
    </ul>
    <div v-else class="gray" style="font-style: italic;">
      No bets found...
    </div>
  </div>
</template>



<script>
import Bet from './Bet'

export default {
  name: 'Bets',
  components: {
    Bet
  },
  props: ['account', 'balance', 'isMetamaskNetworkLoginReady'],
  data () {
    return {
      numBets: 0,
      hideFinishedMatches: false,
      registry: null,
      contract: null
    }
  },
  methods: {
    updateNumBets () {
      this.getNumBets().then(num => {
        this.numBets = Number(num)
      })
    }
  },
  created () {
    this.registry = this.getBetRegistryInstance()
    this.contract = this.getBetContract()
    console.log("registry" + this.registry + "contract: " + this.contract)
    this.updateNumBets()
  },
}
</script>



