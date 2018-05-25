<template v-if="!(hideFinishedMatches && matchFinished)">
  <li class="bet container">
    <div class="row">
      <div class="five columns">
        <h5>{{ p1 }}</h5>
      </div>
      <div class="two columns">&nbsp;</div>
      <div class="five columns">
        <h5>{{ p2 }}</h5>
      </div>
    </div>
    <div class="row" style="position: relative;">
      <div class="five columns">
        <img class="flag u-max-full-width" v-bind:src="require(`@/assets/teams/${p1}.png`)">
      </div>
      <div class="two columns">
        <div class="vs">VS</div>
        <div class="match-context">
          {{ matchContext }}
        </div>
        <div class="small">
          Match {{ matchId+1 }}<span class="gray">/60</span>
        </div>
      </div>
      <div class="five columns">
        <img class="flag u-max-full-width" v-bind:src="require(`@/assets/teams/${p2}.png`)">
      </div>
    </div>

    <template v-if="showBetStats">
      <div class="row" v-show="isSignedInMetamask">
        <div class="five columns">
          <i>{{ toEther(myBetsP1) }} {{ unit }}</i>
        </div>
        <div class="two columns small gray" style="line-height: 2.5rem;">Your&nbsp;bets</div>
        <div class="five columns">
          <i>{{ toEther(myBetsP2) }} {{ unit }}</i>
        </div>
      </div>
      <div class="stats">
        <div class="row">
          <div class="eight columns offset-by-two">
            <div class="left">
              Pot: {{ pot }} {{ unit }}
            </div>
            <div class="statsbar-right">
              <div class="statsbar-left" v-bind:style="getLeftBarWidthPool"></div>
            </div> 
          </div>
        </div>
        <div class="row">
          <div class="eight columns offset-by-two">
            <div class="left">
              Number of betters: {{ numBetsPlayer1+numBetsPlayer2 }}
            </div>
            <div class="statsbar-right">
              <div class="statsbar-left" v-bind:style="getLeftBarWidthNum"></div>
            </div> 
          </div>
        </div>
      </div>
    </template>
    
    <!-- The order of these if checks is important, as each check is narrowing down the bet's status further -->
    <div class="row status">
      <div class="eight columns offset-by-two">
        <div v-if="isCancelled">
          <p>
            Bet is cancelled! :(
          </p>
          <p class="timeout">
            Planned match start at:<br>
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>
        <div v-else-if="isInactive">
          <p>
            Match is not open yet for placing bets.
          </p>
          <p class="timeout">
            Bets open at:<br>
            {{ getReadableDate(timeBettingOpens) }}<br>
            Match begins at:<br>
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>
        <div v-else-if="isClaimExpired">
          <p>{{ winner }} won the match!</p>
          <p>
            Payouts expired at:<br>
            {{ getReadableDate(timeClaimsExpire) }}
          </p>
        </div>
        <div v-else-if="isBettingOpen">
          <p>
            Place your bets now!
          </p>

          <!-- TODO: make this nice -->
          <input type="radio" id="p1" v-bind:value="p1" v-model="betTeam">
          <label for="p1">{{ p1 }}</label>
          <br>
          <input type="radio" id="p2" v-bind:value="p2" v-model="betTeam">
          <label for="p2">{{ p2 }}</label>
          <br>
          <span>Your pick: {{ betTeam }}</span><br>

          <input v-model="betAmount" type="number" step="0.1" placeholder="in ETH">
          <button v-on:click="placeBet()">Bet!</button>


          <p class="timeout">
            Bets close at:<br>
            {{ getReadableDate(timeBettingCloses) }}<br>
            Match begins at:<br>
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>
        <div v-else-if="isBettingClosed">
          <p>
            Betting is closed. Match is beginning shortly...
          </p>
          <p class="timeout">
            Match begins at:<br>
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>
        <div v-else-if="isPayout">
          <!-- TODO: do nice styling, change content when result is a draw. Also at payout expired phase ... -->
          <p>{{ winner }} won the match!</p>
          <p>
            The match result is confirmed
            and payouts can be claimed!
          </p>
          <p class="timeout">
            <!-- TODO: Add 'Hurry up' when user has payouts to claim -->
            Payouts expire at:<br>
            {{ getReadableDate(timeClaimsExpire) }}
          </p>
        </div>
        <div v-else-if="isWaitingForConfirm">
          <p>
            Match result was successfully fetched<br>
            and now has to be confirmed...
          </p>
          <p class="timeout">
            Match result to be confirmed until:<br>
            {{ getReadableDate(timeSuggestConfirmEnds) }}
          </p>
          winner: {{ winner }}<br>
        </div>
        <div v-else-if="isPlayingForSure">
          <p>
            Match is in play!
          </p>
          <p class="timeout">
            Match begin was at:<br>
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>
        <div v-else-if="isFetching">
          <p>
            Match result is currently being fetched...
          </p>
          <p class="timeout">
            Match result to be confirmed until:<br>
            {{ getReadableDate(timeSuggestConfirmEnds) }}
          </p>
        </div>
        <div v-else-if="isShouldStartFetch">
          <p>
            Is the match over? If yes, activate the<br>
            smart contract to start fetching the result.
          </p>
          <button class="button" v-on:click="claimWinOrDraw()">
            Activate
            <img v-if="showSpinner" src="../assets/spinner.gif" class="spinner" />
          </button><br>
          <p class="note small">
            Depending on the external data provider, this may take a while...
          </p>
          <p class="timeout">
            Match result to be confirmed until:<br>
            {{ getReadableDate(timeSuggestConfirmEnds) }}
          </p>
        </div>
        <div v-else>
          <p class="warning">
            Unknown bet status. Please contact admin.
            <!-- offer refresh button -->
          </p>
        </div>
      </div>
    </div>
    <div class="row" style="color: #bbb">
      {{ betAddress }}
    </div>
  </li>
</template>




<script>

const monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

const DEFAULT_GAS = 170000
const BET_GAS = 90000
const DEFAULT_GAS_PRICE = 6e9

export default {
  name: 'Bets',
  props: ['web3', 'betRegistry', 'betContract', 'matchId', 'account', 'balance', 'hideFinishedMatches'],
  data () {
    return {
      instance: null,
      betAddress: null,
      rawStatus: '',
      matchContext: '',
      p1: 'Team 1',
      p2: 'Team 2',
      isFetchingStarted: false,
      matchFinished: false,
      isWinnerConfirmed: false,
      myBetsP1: '0',
      myBetsP2: '0',
      totalPlayer1: '0',
      totalPlayer2: '0',
      numBetsPlayer1: 0,
      numBetsPlayer2: 0,
      timeBettingOpens: 0,
      timeBettingCloses: 0,
      timeSuggestConfirmEnds: 0,
      timeClaimsExpire: 0,
      rawWinner: 0, // 1 == p1, 2 == p2, 3 == draw

      betTeam: '',
      betAmount: '',
      showSpinner: false,
    }
  },
  computed: {
    isSignedInMetamask () {
      return this.account != ''
    },
    unit: function () {
      return 'ETH'
    },
    getNow () {
      return (new Date().getTime() / 1000).toFixed(0);
    },
    status () {
      return this.rawStatus == '1' ? 'Active' : 'Cancelled'
    },
    pot () {
      return this.toEther(this.totalPlayer1) + this.toEther(this.totalPlayer2)
    },
    timeMatchStarts: function() {
      return this.timeBettingCloses + 15*60
    },
    timeMatchEndsEarliest: function() {
      return this.timeMatchStarts + 105*60
    },
    showBetStats () {
      return !(this.isCancelled || this.isInactive || this.isClaimExpired)
    },
    isCancelled: function() {
      return this.rawStatus == "0"
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
      return this.matchFinished == true && this.isWinnerConfirmed == true// && this.getNow < this.timeClaimsExpire
    },
    isWaitingForConfirm: function () {
      console.log("call to isWaitingForConfirm")
      return this.matchFinished == true && this.isWinnerConfirmed == false && this.getNow < this.timeSuggestConfirmEnds
    },
    isPlayingForSure: function () {
      console.log("call to isPlayingForSure")
      return this.getNow >= this.timeMatchStarts && this.getNow <= this.timeMatchEndsEarliest
    },
    isFetching: function () {
      console.log("call to isFetching")
      return this.isFetchingStarted == true && this.getNow < this.timeSuggestConfirmEnds
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
    },
    getLeftBarWidthPool () {
      if (this.totalPlayer1 != '0' || this.totalPlayer2 != '0') {
          return "width: " + ((this.toEther(this.totalPlayer1) / (this.toEther(this.totalPlayer1)+this.toEther(this.totalPlayer2))) * 100) + "%;"
      } else {
          return "width: 100%; background-color: #bbb;"
      }
    },
    getLeftBarWidthNum () {
      if (this.numBetsPlayer1 != '0' || this.numBetsPlayer2 != '0') {
        return "width: " + ((this.numBetsPlayer1 / (this.numBetsPlayer1+this.numBetsPlayer2)) * 100) + "%;"
      } else {
        return "width: 100%; background-color: #bbb;"
      }
    }
  },
  methods: {
    getContractState: async function() {
      this.getStatus()
      this.getMatchContext()
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
      if (weiString == '' || weiString == '0') {
        return 0
      }
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
    claimWinOrDraw: async function() {
      this.showSpinner = true;

      this.instance.claimWinOrDraw({
        from: this.account,
        gas: DEFAULT_GAS
      })
      .then(r => {
        this.showSpinner = false;
        this.getContractState()
        console.log('Tx calling claimWinOrDraw is mined! (Tx hash: ' + r.tx + ')')
      })
      .catch(err => {
        this.showSpinner = false;
        console.error('Tx calling claimWinOrDraw failed.')
      })  
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
    getMatchContext: function () {
      this.instance.matchContext.call().then(mc => {
        this.matchContext = mc
      })
    },
    getStatus: function () {
      this.instance.status.call().then(s => {
        this.rawStatus = s
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
  watch: {
    account: function (newAccount) {
      this.getMyBetsP1()
      this.getMyBetsP2()
    }
  }
}
</script>


<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

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
.bet {
  padding: 15px;
  border: 1px solid #eee;
  background-color: rgb(250,250,250);
}
.flag {
  border: 1px solid #ddd;
}
.vs {
  font-size: 4rem;
  font-weight: bold;
}
.match-context {
  margin-top: 5px;
}
.stats {
  margin: 20px 0px;
}
.statsbar-right {
  background-color: rgb(168, 220, 255);
}
.statsbar-left {
  background-color: rgb(207, 255, 168);
  height: 8px;
}
.status {
  margin-top: 25px;
}
.small {
  font-size: 1.2rem;
  line-height: 1.3;
}
.button {
  width: 200px;
  position: relative;
}
.spinner {
  float: right;
  position: absolute;
  right: 0;
}
.note {
  margin: 10px 0px;
}
.timeout {
  margin: 20px 0px;
  color: orange;
  font-style: italic;
}
</style>

<!-- TODO: improve default rendered content that shows at the very beginning of the loading. -->