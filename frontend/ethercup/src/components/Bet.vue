<template>
  <li class="bet">
    <h2>{{ matchId }}</h2>

    matchId: {{ matchId }}<br>
    status: {{ status }}<br>
    group: {{ group }}<br>
    p1: {{ p1 }}<br>
    p2: {{ p2 }}<br>


    <!-- The order of these if checks is important, as each check is narrowing down the bet's status further -->
    <div v-if="isCancelled">
      Cancelled
    </div>
    <div v-else-if="isInactive">
      isInactive<br>
      timeBettingOpens: {{ getReadableDate(timeBettingOpens) }}<br>
    </div>
    <div v-else-if="isClaimExpired">
      isClaimExpired<br>
      winner: {{ winner }}<br>
    </div>
    <div v-else-if="isBettingOpen">
      isBettingOpen<br>
      timeBettingCloses: {{ getReadableDate(timeBettingCloses) }}<br>
      timeMatchStarts: {{ getReadableDate(timeMatchStarts) }}<br>
      totalPlayer1: {{ toEther(totalPlayer1) }} {{ unit }}<br>
      totalPlayer2: {{ toEther(totalPlayer2) }} {{ unit }}<br>
      numBetsPlayer1: {{ numBetsPlayer1 }}<br>
      numBetsPlayer2: {{ numBetsPlayer2 }}<br> 
    </div>
    <div v-else-if="isBettingClosed">
      isBettingClosed<br>
      myBetsP1: {{ toEther(myBetsP1) }} {{ unit }}<br>
      myBetsP2: {{ toEther(myBetsP2) }}<br>
      totalPlayer1: {{ toEther(totalPlayer1) }} {{ unit }}<br>
      totalPlayer2: {{ toEther(totalPlayer2) }} {{ unit }}<br>
      numBetsPlayer1: {{ numBetsPlayer1 }}<br>
      numBetsPlayer2: {{ numBetsPlayer2 }}<br> 
    </div>
    <div v-else-if="isPayout">
      isPayout<br>
      myBetsP1: {{ toEther(myBetsP1) }} {{ unit }}<br>
      myBetsP2: {{ toEther(myBetsP2) }}<br>
      timeClaimsExpire: {{ getReadableDate(timeClaimsExpire) }}<br>
      totalPlayer1: {{ toEther(totalPlayer1) }} {{ unit }}<br>
      totalPlayer2: {{ toEther(totalPlayer2) }} {{ unit }}<br>
      numBetsPlayer1: {{ numBetsPlayer1 }}<br>
      numBetsPlayer2: {{ numBetsPlayer2 }}<br>
      winner: {{ winner }}<br> 
    </div>
    <div v-else-if="isWaitingForConfirm">
      isWaitingForConfirm<br>
      myBetsP1: {{ toEther(myBetsP1) }} {{ unit }}<br>
      myBetsP2: {{ toEther(myBetsP2) }}<br>
      timeSuggestConfirmEnds: {{ getReadableDate(timeSuggestConfirmEnds) }}<br>
      totalPlayer1: {{ toEther(totalPlayer1) }} {{ unit }}<br>
      totalPlayer2: {{ toEther(totalPlayer2) }} {{ unit }}<br>
      numBetsPlayer1: {{ numBetsPlayer1 }}<br>
      numBetsPlayer2: {{ numBetsPlayer2 }}<br>
      winner: {{ winner }}<br>
    </div>
    <div v-else-if="isPlayingForSure">
      isPlayingForSure<br>
      myBetsP1: {{ toEther(myBetsP1) }} {{ unit }}<br>
      myBetsP2: {{ toEther(myBetsP2) }}<br>
      totalPlayer1: {{ toEther(totalPlayer1) }} {{ unit }}<br>
      totalPlayer2: {{ toEther(totalPlayer2) }} {{ unit }}<br>
      numBetsPlayer1: {{ numBetsPlayer1 }}<br>
      numBetsPlayer2: {{ numBetsPlayer2 }}<br> 
    </div>
    <div v-else-if="isFetching">
      isFetching<br>
      myBetsP1: {{ toEther(myBetsP1) }} {{ unit }}<br>
      myBetsP2: {{ toEther(myBetsP2) }}<br>
      timeSuggestConfirmEnds: {{ getReadableDate(timeSuggestConfirmEnds) 
      }}<br>
      totalPlayer1: {{ toEther(totalPlayer1) }} {{ unit }}<br>
      totalPlayer2: {{ toEther(totalPlayer2) }} {{ unit }}<br>
      numBetsPlayer1: {{ numBetsPlayer1 }}<br>
      numBetsPlayer2: {{ numBetsPlayer2 }}<br> 
    </div>
    <div v-else-if="isShouldStartFetch">
      isShouldStartFetch<br>
      myBetsP1: {{ toEther(myBetsP1) }} {{ unit }}<br>
      myBetsP2: {{ toEther(myBetsP2) }}<br>
      timeSuggestConfirmEnds: {{ getReadableDate(timeSuggestConfirmEnds) }}<br>
      totalPlayer1: {{ toEther(totalPlayer1) }} {{ unit }}<br>
      totalPlayer2: {{ toEther(totalPlayer2) }} {{ unit }}<br>
      numBetsPlayer1: {{ numBetsPlayer1 }}<br>
      numBetsPlayer2: {{ numBetsPlayer2 }}<br> 
    </div>
    <div v-else>
      UNKNOWN PHASE/STATUS. Please contact admin
    </div>
    
    <!--
    matchFinished: {{ matchFinished }}
    winner: {{ winner }}<br>
    isWinnerConfirmed: {{ isWinnerConfirmed }}<br>
    isFetchingStarted: {{ isFetchingStarted }}<br>
    -->

    <input type="radio" id="p1" v-bind:value="p1" v-model="betTeam">
    <label for="p1">{{ p1 }}</label>
    <br>
    <input type="radio" id="p2" v-bind:value="p2" v-model="betTeam">
    <label for="p2">{{ p2 }}</label>
    <br>
    <span>Picked: {{ betTeam }}</span><br>

    <input v-model="betAmount" type="number" step="0.1" placeholder="in ETH">
    <button v-on:click="placeBet()">Bet!</button>
    {{ result }}
  </li>
</template>




<script>

const monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

const DEFAULT_GAS = 150000
const BET_GAS = 90000
const DEFAULT_GAS_PRICE = 6e9

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
      p2: '',
      isFetchingStarted: false,
      matchFinished: false,
      isWinnerConfirmed: false,
      myBetsP1: '',
      myBetsP2: '',
      totalPlayer1: '',
      totalPlayer2: '',
      numBetsPlayer1: 0,
      numBetsPlayer2: 0,
      timeBettingOpens: 0,
      timeBettingCloses: 0,
      timeSuggestConfirmEnds: 0,
      timeClaimsExpire: 0,
      rawWinner: 0, // 1 == p1, 2 == p2, 3 == draw

      betTeam: '',
      betAmount: '',
      result: '',
    }
  },
  computed: {
    unit: function () {
      return 'ETH'
    },
    getNow () {
      return (new Date().getTime() / 1000).toFixed(0);
    },

    timeMatchStarts: function() {
      return this.timeBettingCloses + 15*60
    },
    timeMatchEndsEarliest: function() {
      return this.timeMatchStarts + 105*60
    },
    isCancelled: function() {
      return this.status == "0"
    },
    isInactive: function () {
      console.log("call to isInactive")
      return this.getNow < this.timeBettingOpens
    },
    isClaimExpired: function() {
      console.log("call to isClaimExpired")
      return this.getNow > this.timeClaimsExpire
    },
    isBettingOpen: function () {
      console.log("call to isBettingOpen")
      return this.getNow >= this.timeBettingCloses && this.getNow < this.timeBettingCloses
    },
    isBettingClosed: function () {
      console.log("call to isBettingClosed")
      return this.getNow >= this.timeBettingCloses && this.getNow < this.timeMatchStarts
    },
    isPayout: function () {
      console.log("call to isPayout")
      return this.matchFinished == true && this.isWinnerConfirmed() == true// && this.getNow < this.timeClaimsExpire
    },
    isWaitingForConfirm: function () {
      console.log("call to isWaitingForConfirm")
      return this.matchFinished == true && this.isWinnerConfirmed() == false && this.getNow < this.timeSuggestConfirmEnds
    },
    isPlayingForSure: function () {
      console.log("call to isPlayingForSure")
      return this.getNow >= this.timeMatchStarts && this.getNow <= this.timeMatchEndsEarliest
    },
    isFetching: function () {
      console.log("call to isFetching")
      return this.isFetchingStarted == true
    },
    isShouldStartFetch: function () {
      console.log("call to isShouldStartFetch")
      return this.isFetchingStarted == false && this.getNow > this.timeMatchEndsEarliest
    },
    winner: function() {
      if (this.rawWinner == 1) {
        return p1
      } else if (this.rawWinner == 2) {
        return p2
      } else if (this.rawWinner == 3) {
        return 'DRAW!'
      } else {
        return 'Undecided'
      }
    }
  },
  methods: {
    getContractState: async function() {
      this.getStatus()
      this.getGroup()
      this.getP1()
      this.getP2()
      this.getMatchFinished()
      this.getMyBetsP1()
      this.getMyBetsP2()
      this.getTotalPlayer1()
      this.getTotalPlayer2()
      this.getNumBetsPlayer1()
      this.getNumBetsPlayer2()
      this.getTimeBettingOpens()
      this.getTimeBettingCloses()
      this.getTimeSuggestConfirmEnds()
      this.getTimeClaimsExpire()
      this.getIsFetchingStarted()
      this.getWinner()
    },
    
    toEther (weiString) {
      return Number(this.web3.utils.fromWei(weiString))
    },
    placeBet: async function() {
      this.result = 'Processing...' // Intermediate erponse

      let wei
      try {
        wei = this.validatePlaceBet(this.betTeam, this.betAmount)
      } catch (err) {
        this.result = 'Invalid input'
        return
      }

      if (this.betTeam == this.p1) {
        this.instance.betOnPlayer1({
          from: this.account,
          gas: BET_GAS,
          value: wei
        })
        .then(r => {
          this.result = 'Success! (Tx hash: ' + r.tx + ')'
        })
        .catch(err => {
          this.result = 'Transaction failed.'
        })  
      } else if (this.betTeam == this.p2) {
        this.instance.betOnPlayer2({
          from: this.account,
          gas: BET_GAS,
          value: wei
        })
        .then(r => {
          this.result = 'Success! (Tx hash: ' + r.tx + ')'
        })
        .catch(err => {
          this.result = 'Transaction failed.'
        })  
      }
    },
    validatePlaceBet(team, ether) {
      let wei = this.web3.utils.toWei(ether)

      if ((team == this.p1 || team == this.p2) && wei !== '0') {
        return wei
      } else {
        throw "select a team or bet more than 0"
      }
    },
    getAddressAndInstance () {
      var that = this
      this.betContract.defaults({
        gas: DEFAULT_GAS,
        gasPrice: DEFAULT_GAS_PRICE
      })
      return new Promise(function(resolve, reject) {
        that.betRegistry.betContracts.call(that.matchId).then(addr => {
          that.betAddress = addr
          that.instance = that.betContract.at(addr);
          //console.log(this.instance)
          resolve()
        });
      });
    },
    getGroup: function () {
      this.instance.isGroupPhase.call().then(isGroupPhase => {
        if(isGroupPhase) {
          this.instance.group.call().then(g => {
            this.group = g
          })  
        }  
      })
    },
    getStatus: function () {
      this.instance.status.call().then(s => {
        this.status = s
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
    },
    getMatchFinished: function() {
      this.instance.matchFinished.call().then(matchFinished => {
        this.matchFinished = matchFinished
      })
    },
    getMyBetsP1: async function () {
      this.myBetsP1 = (await this.instance.betsPlayer1.call(this.account)).toString()
    },
    getMyBetsP2: async function () {
      this.myBetsP2 = (await this.instance.betsPlayer2.call(this.account)).toString()
    },
    getTotalPlayer1: async function () {
      this.totalPlayer1 = (await this.instance.totalPlayer1.call()).toString()
    },
    getTotalPlayer2: async function () {
      this.totalPlayer2 = (await this.instance.totalPlayer2.call()).toString()
    },
    getNumBetsPlayer1: async function () {
      this.numBetsPlayer1 = Number(await this.instance.numBetsPlayer1.call())
    },
    getNumBetsPlayer2: async function () {
      this.numBetsPlayer2 = Number(await this.instance.numBetsPlayer2.call())
    },
    getTimeBettingOpens: async function () {
      this.timeBettingOpens = Number(await this.instance.timeBettingOpens.call())
    },
    getTimeBettingCloses: async function() {
      this.timeBettingCloses = Number(await this.instance.timeBettingCloses.call())
    },
    getTimeSuggestConfirmEnds: async function() {
      this.timeSuggestConfirmEnds = Number(await this.instance.timeSuggestConfirmEnds.call())
    },
    getTimeClaimsExpire: async function() {
      this.timeClaimsExpire = Number(await this.instance.timeClaimsExpire.call())
    },
    getIsWinnerConfirmed: async function() {
      this.isWinnerConfirmed = await this.instance.winnerConfirmed.call()
    },
    getWinner: async function() {
      this.instance.winner.call().then(winner => {
          console.log("Winner: " + winner)
          this.rawWinner = winner;  
      })
    },
    getIsFetchingStarted: async function() {
      this.isFetchingStarted = await this.instance.isFetchingStarted.call()
    },
    getReadableDate: function(timestamp) {
      var date = new Date(timestamp*1000)
      return date.getDate() + " " + monthNames[date.getMonth()] + " " + date.getFullYear() + ", " + date.getHours() + ":" + ('0' + date.getMinutes()).slice(-2);
    }
  },
  created () {
    var that = this
    this.getAddressAndInstance().then(function() {
      that.getContractState()
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
  color
  : #42b983;
}
</style>