<template>
  <li class="bet">
    <h2>{{ matchId }}</h2>

    matchId: {{ matchId }}<br>
    status: {{ status }}<br>
    group: {{ group }}<br>
    p1: {{ p1 }}<br>
    p2: {{ p2 }}<br>
    <!--timeBettingOpens: {{ timeBettingOpens }}<br>
    timeBettingCloses: {{ timeBettingCloses }}<br>
    matchFinished: {{ matchFinished }}<br>
    timeClaimsExpire: {{ timeClaimsExpire }}<br>
    timeSuggestConfirmEnds: {{ timeSuggestConfirmEnds }}<br>
    winnerSuggested: {{ isWinnerConfirmed }}<br>
    winner: {{ winner }}<br>
    totalPlayer1: {{ totalPlayer1 }}<br>
    totalPlayer2: {{ totalPlayer2 }}<br>
    numBetsPlayer1: {{ numBetsPlayer1 }}<br>
    numBetsPlayer2: {{ numBetsPlayer2 }}<br> 
-->
    <button v-on:click="placeBet($index)">Bet!</button>
  </li>
</template>




<script>

export default {
  name: 'Bets',
  props: ['web3', 'betRegistry', 'betContract', 'matchId', 'account', 'balance'],
  data () {
    return {
      instance: null,
      betAddress: null,
      status: 0,
      group: '',
      p1: '',
      p2: ''
    }
  },
  computed: {
    group: async function () {
      isGroupPhase = await this.instance.isGroupPhase.call()
      if(isGroupPhase) {
        return await this.instance.group.call()
      }
    },
    p1: async function() {
      return await this.instance.p1.call()
    },
    p2: async function() {
      return await this.instance.p2.call()
    },
    matchFinished: async function() {
      return await this.instance.matchFinished.call()
    },
    myBetsP1: async function () {
      return await this.instance.betsPlayer1(this.account)
    },
    myBetsP2: async function () {
      return await this.instance.betsPlayer2(this.account)
    },
    totalPlayer1: async function () {
      return await this.instance.totalPlayer1.call()
    },
    totalPlayer2: async function () {
      return await this.instance.totalPlayer2.call()
    },
    numBetsPlayer1: async function () {
      return await this.instance.numBetsPlayer1.call()
    },
    numBetsPlayer2: async function () {
      return await this.instance.numBetsPlayer2.call()
    },
    timeBettingOpens: async function() {
      var date = new Date(await this.instance.timeBettingOpens.call() * 1000)
      return this.getReadableDate(date)
    },
    timeBettingCloses: async function() {
      var date = new Date(await this.instance.timeBettingCloses.call() * 1000)
      return this.getReadableDate(date)
    },
    timeSuggestConfirmEnds: async function() {
      var date = new Date(await this.instance.timeSuggestConfirmEnds.call() * 1000)
      return this.getReadableDate(date)
    },
    timeClaimsExpire: async function() {
      var date = new Date(await this.instance.timeClaimsExpire.call() * 1000)
      return this.getReadableDate(date)
    }
  },
  methods: { // not cached. Run every time the method is called
    // a method invocation will always run the function whenever a re-render happens.
    async getWinner () {
      var winner = await this.instance.winner.call()
      var isWinnerConfirmed = await this.instance.winnerConfirmed.call()
      if (isWinnerConfirmed) {
        this.winner = winner; //
      }
    },
    placeBet () {
      this.answer = 'Thinking...' // Intermediate erponse
      var result = web3.contract.placeBetOnPlayer1();
      this.answer = result.result;
    },
    getAddressAndInstance () {
      var that = this
      return new Promise(function(resolve, reject) {
        that.betRegistry.betContracts.call(that.matchId).then(addr => {
          that.betAddress = addr
          that.instance = that.betContract.at(addr);
          //console.log(this.instance)
          resolve()
        });
      });
    },
    getReadableDate (date) {
      return date.getFullYear() + "-" + date.getMonth()+1 + "-" + date.getDate() + " " + date.getHours() + ":" + date.getMinutes();
    },
    getStatus: function () {
      this.instance.status.call().then(s => {
        this.status = Number(s)
      })
    },
    getGroup: function () {
      this.instance.group.call().then(s => {
        this.group = s
      })
    },
    getP1: function () {
      this.instance.p1.call().then(s => {
        this.p1 = s
      })
    },
    getP2: function () {
      this.instance.p2.call().then(s => {
        this.p2 = s
      })
    }
  },
  created () {
    var that = this
    this.getAddressAndInstance().then(function() {
      that.getStatus()
      that.getGroup()
      that.getP1()
      that.getP2()
    })
    
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