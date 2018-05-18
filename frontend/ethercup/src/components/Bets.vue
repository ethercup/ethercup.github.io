<template>
  <div class="thebets">
    <h1>{{ headline }}</h1>
    <ul>
      <Bet
        v-for="(bet, index) in bets" :key="bet.id"
        v-bind:bet="bet"
        v-bind:key="bet.matchId"
      />
    </ul>
</div>
</template>



<script>
import Bet from './Bet'

export default {
  name: 'Bets',
  components: {
    Bet
  },
  data () {
    return {
      headline: 'Bets',
      bets: [
        { id: 0, apiId: '0000' },
        { id: 1, apiId: '1111' },
        { id: 2, apiId: '2222' },
        { id: 3, apiId: '3333' },
        { id: 4, apiId: '4444' }
      ]
    }
  },
  // hook executed after instance is created
  created: function () {
    console.log('Bets created.')// + this.a) // this==vm instance
  }
}
</script>



