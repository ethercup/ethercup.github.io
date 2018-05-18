<template>
  <li class="bet">
    <h2>{{ bet.id }}</h2>

    matchId: {{ bet.matchId }}<br>
    status: {{ bet.status }}<br>
    group: {{ bet.group }}<br>
    isGroupPhase: {{ bet.isGroupPhase }}<br>
    p1: {{ bet.p1 }}<br>
    p2: {{ bet.p2 }}<br>
    timeBettingOpens: {{ bet.timeBettingOpens }}<br>
    timeBettingCloses: {{ bet.timeBettingCloses }}<br>
    matchFinished: {{ bet.matchFinished }}<br>
    timeClaimsExpire: {{ bet.timeClaimsExpire }}<br>
    timeSuggestConfirmEnds: {{ bet.timeSuggestConfirmEnds }}<br>
    winnerSuggested: {{ bet.winnerSuggested }}<br>
    winnerConfirmed: {{ bet.winnerConfirmed }}<br>
    winner: {{ bet.winner }}<br>
    totalPlayer1: {{ bet.totalPlayer1 }}<br>
    totalPlayer2: {{ bet.totalPlayer2 }}<br>
    numBetsPlayer1: {{ bet.numBetsPlayer1 }}<br>
    numBetsPlayer2: {{ bet.numBetsPlayer2 }}<br>
  
 

    <button v-on:click="placeBet($index)">Bet!</button>
  </li>
</template>




<script>

export default {
  name: 'Bets',
  props: ['bet'],
  // data () {
  //   return {
  //     id: 0,
  //     apiId: '111'
  //   }
  // }
  computed: { // will be cached, only changed when base variable changes
    myBetsP1: function () {
      return web.instance.betsPlayer1(address) // only run once, will never update
    },
    myBetsP2: function () {
      return web.instance.betsPlayer2(address) // only run once, will never update
    },
    timeBettingOpens: function() {
      return 0;//human readable format of this.bet.timeBettingOpens
    },
    timeBettingCloses: function() {
      return 0;//human readable format of this.bet.timeBettingCloses
    },
    timeSuggestConfirmEnds: function() {
      return 0;//human readable format of this.bet.timeSuggestConfirmEnds
    },
    timeClaimsExpire: function() {
      return 0;//human readable format of this.bet.timeClaimsExpire
    },
    winner: function () {
      if (bet.winnerConfirmed) {
        return bet.winner == 1 ? bet.p1 : bet.winner == 2 ? bet.p2 : "Draw";
      }
    }
  },
  methods: { // not cached. Run every time the method is called
    // a method invocation will always run the function whenever a re-render happens.
    placeBet: function () {
      this.answer = 'Thinking...' // Intermediate erponse
      var result = web3.contract.placeBetOnPlayer1();
      this.answer = result.result;
    }
  },
  watch: { // listen for changes on variables in 'data'. Usually a computed-propery is favorable
    firstName: function (val) {
      this.fullName = val + ' ' + this.lastName
    },
    question: function (someInput) {
      this.runAsyncFunctionDefinedInMethods()
      this.palceBet()
    }
  }
}
</script>


<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

h1, h2 {
  font-weight: normal;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}

</style>