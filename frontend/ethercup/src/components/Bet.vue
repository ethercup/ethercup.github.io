<template>
  <li v-if="showBet" class="bet container">
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
        <img
          class="flag selectable u-max-full-width"
          v-bind:src="require(`@/assets/teams/${p1}.png`)"
          v-on:click.stop.prevent="select(p1)"
          v-bind:class="{ notselected : isP2Selected, selected : isP1Selected }">
      </div>
      <div class="two columns">
        <div class="vs">VS</div>
        <div class="match-context">
          {{ matchContext }}
        </div>
        <div class="small">
          Match {{ matchId+1 }}<span class="gray">/64</span>
        </div>
      </div>
      <div class="five columns">
        <img
          class="flag selectable u-max-full-width"
          v-bind:src="require(`@/assets/teams/${p2}.png`)"
          v-on:click.stop.prevent="select(p2)"
          v-bind:class="{ notselected : isP1Selected, selected : isP2Selected }">
      </div>
    </div>

    <template v-if="showBetStats">
      <div class="row" v-show="isMetamaskNetworkLoginReady">
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
              Number of bets: {{ numBetsPlayer1+numBetsPlayer2 }}
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

        <!-- CANCELLED -->

        <div v-if="isCancelled">
          <BetPhaseCancelled
            :instance="instance"
            :timeMatchStarts="timeMatchStarts"
            :hasPayouts="hasPayouts"
            @claimed="updateContractBetState()"/>
        </div>

        <!-- INACTIVE -->

        <div v-else-if="isInactive">
          <BetPhaseInactive
            :timeBettingOpens="timeBettingOpens"
            :timeMatchStarts="timeMatchStarts"/>
        </div>

        <!-- CLAIM EXPIRED -->

        <div v-else-if="isClaimExpired">
          <BetPhaseExpired
            :getWinnerPhase="getWinnerPhase"/>
        </div>

        <!-- BETTING OPEN -->

        <div v-else-if="isBettingOpen">
          <BetPhaseOpen
            v-bind:instance="instance"
            v-bind:p1:"p1"
            v-bind:p2:"p2"
            v-bind:betTeam="betTeam"
            v-bind:timeBettingCloses="timeBettingCloses"
            v-bind:timeMatchStarts="timeMatchStarts"
            @bet-placed="updateContractBetState()">
          </BetPhaseOpen>
        </div>

        <!-- BETTING CLOSED -->

        <div v-else-if="isBettingClosed">
          <BetPhaseClosed
            :timeMatchStarts="timeMatchStarts"/>
        </div>

        <!-- PAYOUT -->

        <div v-else-if="isPayout">
          <BetPhasePayout
            v-bind:instance="instance"
            v-bind:timeClaimsExpire="timeClaimsExpire"
            v-bind:hasPayouts="hasPayouts"
            v-bind:getWinnerPhrase="getWinnerPhrase"
            @claimed="getContractState()">
          </BetPhasePayout>
        </div>

        <!-- WAIT CONFIRM -->

        <div v-else-if="isWaitingForConfirm">
          <BetPhaseWaitForConfirm
            :timeSuggestConfirmEnds="timeSuggestConfirmEnds"
            :getWinnerPhrase="getWinnerPhrase"/>
        </div>

        <!-- TOO LATE FOR CONFIRM -->

        <div v-else-if="isTooLateForConfirm">
          <BetPhaseTooLateConfirm
            :instance="instance"
            :timeSuggestConfirmEnds="timeSuggestConfirmEnds"
            @claimed="getContractState()"/>
        </div>

        <!-- MATCH IN PLAY -->

        <div v-else-if="isPlayingForSure">
          <BetPhaseMatchInPlay
            :timeMatchStarts="timeMatchStarts"
          />
        </div>

        <!-- IS FETCHING -->

        <div v-else-if="isFetching">
          <BetPhaseFetching
            :timeSuggestConfirmEnds="timeSuggestConfirmEnds"/>
        </div>

        <!-- SHOULD START FETCH -->

        <div v-else-if="isShouldStartFetch">
          <BetPhaseShouldStartFetch
            v-bind:instance="instance"
            v-bind:matchId="matchId"
            v-bind:account="account"
            v-bind:timeSuggestConfirmEnds="timeSuggestConfirmEnds"
            @claimed="getContractState()">
            >
          </BetPhaseShouldStartFetch>
        </div>

        <!-- UNKNOWN -->

        <div v-else>
          <BetPhaseUnknown
            :timeMatchStarts="timeMatchStarts"/>
        </div>
      </div>
    </div>
    <div class="row monospace">
      <a v-bind:href="etherscanURL" target="_blank" class="gray">
        {{ address }}
      </a>
    </div>
  </li>
</template>

<script>
import { mapState, mapGetters } from 'vuex'
import BetPhaseCancelled from './phases/BetPhaseCancelled.vue'
import BetPhaseMatchInPlay from './phases/BetPhaseMatchInPlay.vue'
import BetPhaseExpired from './phases/BetPhaseExpired.vue'
import BetPhaseInactive from './phases/BetPhaseInactive.vue'
import BetPhasePayout from './phases/BetPhasePayout.vue'
import BetPhaseOpen from './phases/BetPhaseOpen.vue'
import BetPhaseClosed from './phases/BetPhaseClosed.vue'
import BetPhaseShouldStartFetch from './phases/BetPhaseShouldStartFetch.vue'
import BetPhaseWaitForConfirm from './phases/BetPhaseWaitForConfirm'
import BetPhaseTooLateConfirm from './phases/BetPhaseTooLateConfirm.vue'
import BetPhaseUnknown from './phases/BetPhaseUnknown.vue'
import BetPhaseFetching from './phases/BetPhaseFetching.vue'

const monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

export default {
  name: 'Bets',
  components: {
    BetPhaseCancelled, BetPhaseMatchInPlay, BetPhaseExpired, BetPhaseInactive, BetPhasePayout, BetPhaseOpen, BetPhaseClosed, BetPhaseShouldStartFetch, BetPhaseWaitForConfirm, BetPhaseTooLateConfirm, BetPhaseFetching, BetPhaseUnknown
  },
  props: ['matchId', 'registryInstance', 'hideFinishedMatches'],
  data () {
    return {
      // bet contract
      instance: null,
      address: '',
      // bet state data
      rawStatus: '',
      matchContext: '',
      p1: 'Team 1',
      p2: 'Team 2',
      isFetchingStarted: false,
      matchFinished: false,
      isWinnerSuggested: false,
      isWinnerConfirmed: false,
      myBetsP1: '0',
      myBetsP2: '0',
      totalPlayer1: '0',
      totalPlayer2: '0',
      numBetsPlayer1: 0,
      numBetsPlayer2: 0,
      timeBettingOpens: 1577836800,
      timeBettingCloses: 1577836800,
      timeSuggestConfirmEnds: 1577836800,
      timeClaimsExpire: 1577836800, // high inital value to improve UX
      rawWinner: 0, // 1 == p1, 2 == p2, 3 == draw

      // UI data
      betTeam: '',
      betAmount: '',
      showSpinner: false,
      warning: '',
      success: ''
    }
  },
  computed: {
    ...mapState({
      web3: state => state.web3,
      contract: state => state.bets.contract,
      account: state => state.account
    }),
    ...mapGetters({
      isMetamaskNetworkLoginReady: 'isMetamaskNetworkLoginReady'
    }),
    etherscanURL () {
      return process.env.ETHERSCAN_URL + this.address + process.env.ETHERSCAN_APPENDIX
    },
    unit () {
      return 'ETH'
    },
    getNow () {
      return (new Date().getTime() / 1000).toFixed(0);
    },
    status () {
      return this.rawStatus == '1' ? 'Active' : 'Cancelled'
    },
    pot () {
      return (this.toEther(this.totalPlayer1) + this.toEther(this.totalPlayer2)).toFixed(3)
    },
    timeMatchStarts: function() {
      return this.timeBettingCloses + 15*60
    },
    timeMatchEndsEarliest: function() {
      return this.timeMatchStarts + 105*60
    },
    showBet () {
      return !(this.hideFinishedMatches && this.matchFinished)
    },
    showBetStats () {
      return !(this.isInactive || this.isClaimExpired)
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
      return this.getNow >= this.timeBettingOpens &&
        this.getNow < this.timeBettingCloses
    },
    isBettingClosed: function () {
      console.log("call to isBettingClosed")
      return this.getNow >= this.timeBettingCloses && this.getNow < this.timeMatchStarts
    },
    isPayout: function () {
      console.log("call to isPayout")
      return this.matchFinished == true &&
        this.isWinnerConfirmed == true// && this.getNow < this.timeClaimsExpire
    },
    isWaitingForConfirm: function () {
      console.log("call to isWaitingForConfirm")
      return this.matchFinished == true &&
        this.isWinnerSuggested == true &&
        this.isWinnerConfirmed == false &&
        this.getNow < this.timeSuggestConfirmEnds
    },
    isTooLateForConfirm: function () {
      console.log("call to isTooLateForConfirm")
      return this.matchFinished == true &&
        this.isWinnerSuggested == true &&
        this.isWinnerConfirmed == false &&
        this.getNow >= this.timeSuggestConfirmEnds
    },
    isPlayingForSure: function () {
      console.log("call to isPlayingForSure")
      return this.getNow >= this.timeMatchStarts &&
        this.getNow <= this.timeMatchEndsEarliest
    },
    isFetching: function () {
      console.log("call to isFetching")
      return this.isFetchingStarted == true && this.isWinnerSuggested == false &&
        this.getNow < this.timeSuggestConfirmEnds
    },
    isShouldStartFetch: function () {
      return this.isFetchingStarted == false &&
        this.getNow > this.timeMatchEndsEarliest
    },
    getWinnerPhrase: function() {
      if (this.rawWinner == 1) {
        return this.p1 + ' won the match!'
      } else if (this.rawWinner == 2) {
        return this.p2 + ' won the match!'
      } else {
        return 'Match resulted in a draw!'
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
    },
    isP1Selected () {
      return this.betTeam === this.p1
    },
    isP2Selected () {
      return this.betTeam === this.p2
    },
    hasPayouts () {
      if (this.rawWinner == 1 && this.myBetsP1 != '0') {
        return true
      } else if (this.rawWinner == 2 && this.myBetsP2 != '0') {
        return true
      } else if (this.rawWinner == 3 && (this.myBetsP1 != '0' || this.myBetsP2 != '0')) {
        return true
      } else {
        return false
      }
    }
  },
  methods: {
    getContractState: async function() {
      this.getStatus()
      this.getMatchContext()
      this.getP1()
      this.getP2()
      this.updateContractBetState()
      this.getMatchFinished()
      this.getTimeBettingOpens()
      this.getTimeBettingCloses()
      this.getTimeSuggestConfirmEnds()
      this.getTimeClaimsExpire()
      this.getIsFetchingStarted()
      this.getIsWinnerSuggested()
      this.getIsWinnerConfirmed()
      this.getWinner()
    },
    updateContractBetState: async function() {
      this.getMyBetsP1()
      this.getMyBetsP2()
      this.getTotalPlayer1()
      this.getTotalPlayer2()
      this.getNumBetsPlayer1()
      this.getNumBetsPlayer2()
    },
    toEther (weiString) {
      if (weiString == '' || weiString == '0') {
        return 0
      }
      return Number(this.web3.utils.fromWei(weiString))
    },
    select: async function (player) {
      if(this.isBettingOpen) {
        if (player == this.p1) {
          this.betTeam = this.p1
        } else {
          this.betTeam = this.p2
        }
        console.log(this.betTeam + " selected.")
      }
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
      this.instance.matchFinished.call().then(mf => {
        this.matchFinished = mf
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
    getIsWinnerSuggested: async function() {
      this.isWinnerSuggested = await this.instance.winnerSuggested.call()
    },
    getIsWinnerConfirmed: async function() {
      this.isWinnerConfirmed = await this.instance.winnerConfirmed.call()
    },
    getWinner: async function() {
      this.instance.winner.call().then(winner => {
        this.rawWinner = Number(winner);  
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
    this.registryInstance.betContracts.call(this.matchId).then(address => {
      this.address = address
      this.contract.at(address).then(instance => {
        this.instance = instance
        this.getContractState()
      })
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
.bet {
  margin: 15px 0px;
  padding: 15px;
  border: 1px solid #bbb;
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
.input {
  width: 100%;
  margin-bottom: 0.5rem;
}
.note {
  margin: 20px 0px;
}
.times {
  margin: 20px 0px;
  font-style: italic;
}
.timeout {
  color: orange;
}
.matchstart {
  color: rgb(111, 175, 38);
}
.selectable {
  cursor: pointer;
}
.notselected {
  filter: grayscale(50%);
}
.selected {
  border: none;
  outline: 6px solid rgb(111, 175, 38);
}
</style>

<!-- TODO: improve default rendered content that shows at the very beginning of the loading. -->