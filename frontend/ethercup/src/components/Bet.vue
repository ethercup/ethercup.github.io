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
          <p class="announcement">
            Bet is cancelled! :(
          </p>
          <p class="timeout">
            Planned match start at:<br>
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>

        <!-- INACTIVE -->

        <div v-else-if="isInactive">
          <p class="announcement">
            Match is not open yet for placing bets.
          </p>
          <p class="times">
            <span class="matchstart">Bet opens at
            {{ getReadableDate(timeBettingOpens) }}<br>
            Match begins at
            {{ getReadableDate(timeMatchStarts) }}</span>
          </p>
        </div>

        <!-- CLAIM EXPIRED -->

        <div v-else-if="isClaimExpired">
          <p class="matchresult announcement">
            {{ getWinnerPhrase }}
          </p>
          <p class="times">
            <span class="timeout">Payouts expired at<br>
            {{ getReadableDate(timeClaimsExpire) }}</span>
          </p>
        </div>

        <!-- BETTING OPEN -->

        <div v-else-if="isBettingOpen">
          <BetPhaseOpen
            v-bind:timeBettingCloses="timeBettingCloses"
            v-bind:timeMatchStarts="timeMatchStarts"
            v-bind:isMetamaskNetworkLoginReady="isMetamaskNetworkLoginReady">
          </BetPhaseOpen>



          <!--<p class="announcement">
            Place your bets now!
          </p>
          <template v-if="isMetamaskNetworkLoginReady">
            <p class="note small">
              Click on a country's flag to<br>
              select your favorite team.<br>
            </p>
            <p v-if="warning != ''" class="warning">
              {{ warning }}
            </p>
            <p v-if="success != ''" class="success">
              {{ success }}
            </p>
            <div class="row">
              <div class="six columns offset-by-two">
                <input v-model="betAmount" type="number" step="0.1" min="0" placeholder="Your bet" class="input">
              </div>
              <div class="two columns" style="line-height: 4rem; text-align: left;">
                ETH
              </div>
            </div>
            <div class="row">
              <div class="eight columns offset-by-two">
                <button class="button" v-on:click="placeBet()">
                  Bet
                  <img v-if="showSpinner" src="../assets/spinner.gif" class="spinner" />
                </button>
              </div>
            </div>
          </template>
          <template v-else>
            <p class="warning">
              Metamask isn't ready.<br>
              Please log in Metamask and chose Main Ethereum network.
            </p>
          </template>
          <p class="times">
            <span class="timeout">
              Betting closes at {{ getReadableDate(timeBettingCloses) }}
            </span>
            <br>
            <span class="matchstart">Match begins at {{ getReadableDate(timeMatchStarts) }}
            </span>
          </p>-->
        </div>

        <!-- BETTING CLOSED -->

        <div v-else-if="isBettingClosed">
          <p class="announcement">
            Betting is closed. Match is beginning shortly...
          </p>
          <p class="timeout">
            Match begins at 
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>

        <!-- PAYOUT -->


        <div v-else-if="isPayout">
          <BetPhasePayout
            v-bind:timeClaimsExpire="timeClaimsExpire"
            v-bind:isMetamaskNetworkLoginReady="isMetamaskNetworkLoginReady"
            v-bind:hasPayouts="hasPayouts"
            v-bind:getWinnerPhrase="getWinnerPhrase">
          </BetPhasePayout>
        </div>
          <!--<p class="matchresult announcement">
            {{ getWinnerPhrase }}
          </p>
          <template v-if="isMetamaskNetworkLoginReady">
            <p class="note small">
              The match result is confirmed
              and payouts can be claimed now!
            </p>
            <p v-if="warning != ''" class="warning">
              {{ warning }}
            </p>
            <p v-if="success != ''" class="success">
              {{ success }}
            </p>
            <div class="row" v-if="hasPayouts">
              <div class="eight columns offset-by-two">
                <button class="button" v-on:click="claimWinOrDraw()">
                  Claim payout
                  <img v-if="showSpinner" src="../assets/spinner.gif" class="spinner" />
                </button>
              </div>
            </div>
            <div v-else>
              You don't have any payouts to claim.
            </div>
          </template>
          <template v-else>
            <p class="warning">
              Metamask isn't ready.<br>
              Please log in Metamask and chose Main Ethereum network.
            </p>
          </template>
          <p class="times">
            <span class="timeout">
              Payouts expire at<br>
              {{ getReadableDate(timeClaimsExpire) }}
            </span>
          </p>
        </div>-->

        <!-- WAIT CONFIRM -->

        <div v-else-if="isWaitingForConfirm">
          <p class="announcement">
            Match result was successfully fetched<br>
            and now has to be confirmed. Looks like...
            <span class="matchresult">{{ getWinnerPhrase }}</span>
          </p>
          <p class="timeout">
            Match result must be confirmed<br>
            until {{ getReadableDate(timeSuggestConfirmEnds) }}
          </p>
        </div>

        <!-- MATCH IN PLAY -->

        <div v-else-if="isPlayingForSure">
          <p class="announcement">
            Match is in play... <img style="margin-bottom: -2px" src="data:image/svg+xml;utf8;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/Pgo8IS0tIEdlbmVyYXRvcjogQWRvYmUgSWxsdXN0cmF0b3IgMTYuMC4wLCBTVkcgRXhwb3J0IFBsdWctSW4gLiBTVkcgVmVyc2lvbjogNi4wMCBCdWlsZCAwKSAgLS0+CjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+CjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgdmVyc2lvbj0iMS4xIiBpZD0iQ2FwYV8xIiB4PSIwcHgiIHk9IjBweCIgd2lkdGg9IjE2cHgiIGhlaWdodD0iMTZweCIgdmlld0JveD0iMCAwIDcyLjM3MSA3Mi4zNzIiIHN0eWxlPSJlbmFibGUtYmFja2dyb3VuZDpuZXcgMCAwIDcyLjM3MSA3Mi4zNzI7IiB4bWw6c3BhY2U9InByZXNlcnZlIj4KPGc+Cgk8cGF0aCBkPSJNMjIuNTcsMi42NDhjLTQuNDg5LDEuODItOC41MTcsNC40OTYtMTEuOTcxLDcuOTQ5QzcuMTQ0LDE0LjA1MSw0LjQ3MSwxOC4wOCwyLjY1LDIyLjU2OEMwLjg5MiwyNi45MDQsMCwzMS40ODYsMCwzNi4xODYgICBjMCw0LjY5OSwwLjg5Miw5LjI4MSwyLjY1LDEzLjYxNWMxLjgyMSw0LjQ4OSw0LjQ5NSw4LjUxOCw3Ljk0OSwxMS45NzFjMy40NTQsMy40NTUsNy40ODEsNi4xMjksMTEuOTcxLDcuOTQ5ICAgYzQuMzM2LDEuNzYsOC45MTcsMi42NDksMTMuNjE3LDIuNjQ5YzQuNywwLDkuMjgtMC44OTIsMTMuNjE2LTIuNjQ5YzQuNDg4LTEuODIsOC41MTgtNC40OTQsMTEuOTcxLTcuOTQ5ICAgYzMuNDU1LTMuNDUzLDYuMTI5LTcuNDgsNy45NDktMTEuOTcxYzEuNzU4LTQuMzM0LDIuNjQ4LTguOTE2LDIuNjQ4LTEzLjYxNWMwLTQuNy0wLjg5MS05LjI4Mi0yLjY0OC0xMy42MTggICBjLTEuODItNC40ODgtNC40OTYtOC41MTgtNy45NDktMTEuOTcxcy03LjQ3OS02LjEyOS0xMS45NzEtNy45NDlDNDUuNDY3LDAuODkxLDQwLjg4NywwLDM2LjE4NywwICAgQzMxLjQ4NywwLDI2LjkwNiwwLjg5MSwyMi41NywyLjY0OHogTTkuMDQ0LDUxLjQxOWMtMS43NDMtMS4wOTQtMy4zNDktMi4zNTQtNC43NzEtMy44MzhjLTIuMTcyLTYuMTEyLTIuNTQtMTIuNzI5LTEuMTAxLTE5LjAxICAgYzAuNjc3LTEuMzM1LDEuNDQ3LTIuNjE3LDIuMzE4LTMuODQ1YzAuMjY5LTAuMzc5LDAuNTE4LTAuNzc0LDAuODA2LTEuMTQybDguMTY2LDQuODMyYzAsMC4wNjQsMCwwLjEzNCwwLDAuMjA1ICAgYy0wLjAyMSw0LjM5MiwwLjQyNSw4Ljc1MiwxLjMxMywxMy4wNDljMC4wMDMsMC4wMiwwLjAwNiwwLjAzMSwwLjAxLDAuMDQ5bC02LjMzMyw5LjkzQzkuMzE0LDUxLjU3OSw5LjE3Nyw1MS41MDMsOS4wNDQsNTEuNDE5eiAgICBNMzMuMzI0LDY4LjIwNmMxLjQwOSwwLjcxOSwyLjg1OCwxLjMyNiw0LjM0NywxLjgyYy02LjMyNSwwLjI3NS0xMi43MTMtMS4yMDctMTguMzYtNC40NDdMMzMsNjguMDE4ICAgQzMzLjEwNSw2OC4wODUsMzMuMjEyLDY4LjE0OSwzMy4zMjQsNjguMjA2eiBNMzMuMjc0LDY1LjczNUwxNy4xMiw2Mi44NTZjLTEuODktMi4yOTUtMy41OS00LjcyMy01LjA1MS03LjMxOCAgIGMtMC4zNzItMC42Ni0wLjc4Ny0xLjMwMS0xLjEwMi0xLjk5bDYuMzI3LTkuOTJjMC4xNCwwLjAzNSwwLjI5NiwwLjA3MiwwLjQ3MywwLjExOWMzLjk1OCwxLjA1OSw3Ljk4NiwxLjgxMiwxMi4wNDIsMi40MDIgICBjMC4yMzcsMC4wMzMsMC40MzUsMC4wNjIsMC42MDQsMC4wOGw3LjU4NCwxMy4xMTNjLTEuMzE2LDEuODUtMi42NDcsMy42OS00LjAwNyw1LjUxQzMzLjc2NCw2NS4xNTUsMzMuNTI0LDY1LjQ0NiwzMy4yNzQsNjUuNzM1eiAgICBNNjAuMTUsNjAuMTQ5Yy0xLjI4NiwxLjI4Ny0yLjY1MSwyLjQ0Ny00LjA4LDMuNDgxYy0wLjIzNy0xLjg5NC0wLjY0Ni0zLjc1LTEuMjIzLTUuNTYzbDguMDkyLTE1LjA5NiAgIGMyLjIyOS0xLjAxNSw0LjM3OS0yLjE2Niw2LjM3NS0zLjU5M2MwLjI2MS0wLjE4NSwwLjQ3OC0wLjM5MiwwLjY0Ni0wLjYxOEM2OS4zNzQsNDYuNTYxLDY2LjEwNCw1NC4xOTYsNjAuMTUsNjAuMTQ5eiAgICBNNTkuNzkxLDQwLjU3MWMwLjMwMSwwLjU3NCwwLjU5OCwxLjE1NCwwLjg5NiwxLjc0MmwtNy44MTYsMTQuNThjLTAuMDQ1LDAuMDEtMC4wODgsMC4wMi0wLjEzMywwLjAyNiAgIGMtNC4yMjUsMC43ODktOC40ODQsMS4yMDktMTIuNzc5LDEuMjI5bC03LjgtMTMuNDg3YzEuMjE0LTIuMjU0LDIuNDE3LTQuNTE3LDMuNjEtNi43ODFjMC44MS0xLjUzNiwxLjYwNi0zLjA4MiwyLjQwMS00LjYyNyAgIGwxNi4xNDMtMS42NThDNTYuMjksMzQuNDk1LDU4LjE2MywzNy40NTcsNTkuNzkxLDQwLjU3MXogTTU2LjUxNiwyMy4yNzdjLTAuNzY2LDIuMDIzLTEuNTg2LDQuMDI1LTIuNDAxLDYuMDMxbC0xNS43MjYsMS42MTUgICBjLTAuMTg4LTAuMjQ4LTAuMzgzLTAuNDkyLTAuNTg4LTAuNzI1Yy0xLjg1Ny0yLjEwMy0zLjcyNi00LjE5My01LjU5Mi02LjI4OWMwLjAxNy0wLjAyMSwwLjAzNC0wLjAzNywwLjA1MS0wLjA1NiAgIGMtMC43NTMtMC43NTItMS41MDgtMS41MDQtMi4yNjEtMi4yNThsNC4zNzgtMTMuMTgxYzAuMzAyLTAuMDgsMC42MDYtMC4xNDcsMC45MTMtMC4xOGMyLjM4LTAuMjQyLDQuNzYzLTAuNTE2LDcuMTQ5LTAuNjU0ICAgYzEuNDYxLTAuMDgyLDIuOTMtMC4xMjksNC40MTYtMC4wMjRsMTAuODMyLDEyLjIwOUM1Ny4zMTQsMjAuOTQzLDU2Ljk1LDIyLjEyNCw1Ni41MTYsMjMuMjc3eiBNNjAuMTUsMTIuMjIxICAgYzIuOTg4LDIuOTksNS4zMDIsNi40MDIsNi45MzgsMTAuMDQ3Yy0yLjAyNC0xLjM5My00LjE4OC0yLjUzOS02LjQ2My0zLjQ3M2MtMC4zNTQtMC4xNDYtMC43MTctMC4yNzUtMS4wODYtMC40MDJMNDguODc3LDYuMzc2ICAgYzAuMDc0LTAuNTE5LDAuMTEzLTEuMDM5LDAuMTI5LTEuNTYzQzUzLjA2Miw2LjQ2NCw1Ni44NjQsOC45MzYsNjAuMTUsMTIuMjIxeiBNMjUuMzM0LDQuMTgyYzAuMDQyLDAuMDMxLDAuMDYyLDAuMDU3LDAuMDg2LDAuMDY0ICAgYzIuNDM3LDAuODQyLDQuNjU0LDIuMDgyLDYuNzQ0LDMuNTUzbC00LjA5LDEyLjMxN2MtMC4wMjEsMC4wMDYtMC4wNDEsMC4wMTItMC4wNjEsMC4wMjFjLTAuODM3LDAuMzQ2LTEuNjksMC42NTYtMi41MTQsMS4wMzEgICBjLTMuMzk1LDEuNTQzLTYuNzA1LDMuMjUyLTkuODIzLDUuMzAxbC04LjA3MS00Ljc3NWMwLjAxMi0wLjI1MiwwLjA1NS0wLjUwOCwwLjE0MS0wLjczNmMwLjU0Mi0xLjQ0NCwxLjA3NS0yLjg5NiwxLjY4OC00LjMxMSAgIGMwLjQ3Mi0xLjA5LDEuMDEtMi4xNDMsMS41OTctMy4xNzJjMC4zODQtMC40MjQsMC43ODItMC44NDQsMS4xOTItMS4yNTRjMy44MzMtMy44MzIsOC4zNjMtNi41NTMsMTMuMTg2LTguMTYyICAgQzI1LjM4NCw0LjA5OCwyNS4zNTgsNC4xMzksMjUuMzM0LDQuMTgyeiIgZmlsbD0iIzAwMDAwMCIvPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+CjxnPgo8L2c+Cjwvc3ZnPgo=" />
            <br>
            Good luck!
          </p>
          <p class="timeout">
            Match begin was at
            {{ getReadableDate(timeMatchStarts) }}
          </p>
        </div>

        <!-- IS FETCHING -->

        <div v-else-if="isFetching">
          <p class="announcement">
            Match result is currently being fetched...
          </p>
          <p class="timeout">
            Match result to be confirmed until:<br>
            {{ getReadableDate(timeSuggestConfirmEnds) }}
          </p>
        </div>

        <!-- SHOULD START FETCH -->

        <div v-else-if="isShouldStartFetch">
          <BetPhaseShouldStartFetch
            v-bind:matchId="matchId"
            v-bind:account="account"
            v-bind:timeSuggestConfirmEnds="timeSuggestConfirmEnds"
            v-bind:isMetamaskNetworkLoginReady="isMetamaskNetworkLoginReady">
          </BetPhaseShouldStartFetch>
        </div>

        <!-- UNKNOWN -->

        <div v-else>
          <p class="warning announcement">
            Unknown bet status. Please contact the admin.
            <!-- offer refresh button -->
          </p>
        </div>
      </div>
    </div>
    <div class="row monospace" style="color: #bbb">
      {{ bet.addresses[matchId] }}
    </div>
  </li>
</template>




<script>
import BetPhasePayout from './phases/BetPhasePayout.vue'
import BetPhaseOpen from './phases/BetPhaseOpen.vue'
import BetPhaseShouldStartFetch from './phases/BetPhaseShouldStartFetch.vue'

const monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

export default {
  name: 'Bets',
  components: {
    BetPhasePayout, BetPhaseOpen, BetPhaseShouldStartFetch
  },
  props: ['registry', 'contract', 'matchId', 'account', 'balance', 'hideFinishedMatches', 'isMetamaskNetworkLoginReady'],
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

      betTeam: '',
      betAmount: '',
      showSpinner: false,
      warning: '',
      success: ''
    }
  },
  computed: {
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
      console.log("call to isShouldStartFetch")
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
      this.getContractBetState()
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
    getContractBetState: async function() {
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
    placeBet: async function() {
      this.success = ''
      this.warning = ''

      if (this.betTeam != this.p1 && this.betTeam != this.p2) {
        this.warning = 'Please select your favorite team first.'
        return
      }

      let wei
      let weiBN
      try {
        wei = this.web3.utils.toWei(this.betAmount)
        weiBN = this.web3.utils.toBN(wei)
      } catch(err) {
        this.warning = 'Please enter a valid amount of Ether first.'
        return
      }
      if (wei.charAt(0) === '-') {
        this.warning = 'Negative Ether not allowed.'
        return
      }
      if (weiBN < 1e15) {
        this.warning = 'Minimum bet is 0.001 Ether.'
        return
      }

      console.log(wei)

      this.warning = ''
      this.showSpinner = true;
      if (this.betTeam == this.p1) {
        console.log("lets bet on p1")
        this.instance.betOnPlayer1({
          from: this.account,
          gas: BET_GAS,
          value: wei
        })
        .then(r => {
          this.getContractBetState()
          this.showSpinner = false;
          this.success = 'Bet placed successfully!'
          // Tx hash: r.tx
        })
        .catch(err => {
          this.showSpinner = false;
          this.warning = 'Transaction failed or rejected.'
        })
      } else if (this.betTeam == this.p2) {
        console.log("lets bet on p2")
        this.instance.betOnPlayer2({
          from: this.account,
          gas: BET_GAS,
          value: wei
        })
        .then(r => {
          this.getContractBetState()
          this.showSpinner = false;
          this.success = 'Bet placed successfully!'
          //Tx hash: r.tx
        })
        .catch(err => {
          this.showSpinner = false;
          this.warning = 'Transaction failed or rejected'
        })  
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
    this.getBetAddress(this.registry, this.matchId).then(a => {
      this.address = a
      this.instance = this.getBetInstance(this.contract, this.address)
      this.getContractState()
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
.matchresult {
  color: rgb(111, 175, 38);
  font-style: italic;
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
.button {
  width: 100%;
  position: relative;
}
.spinner {
  float: right;
  position: absolute;
  right: 0;
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