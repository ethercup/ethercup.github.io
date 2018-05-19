<template>
  <div class="thebets">
    <h1>{{ headline }}</h1>
    {{account}}
    {{numBets}}
    <ul>
      <Bet
        v-for="n in numBets" :key="n"
        v-bind:matchId="n-1"
        v-bind:web3="web3"
        v-bind:betRegistry="betRegistry.instance"
        v-bind:betContract="betContract"
        v-bind:account="account"
        v-bind:balance="balance"
      />
    </ul>
</div>
</template>



<script>
import Bet from './Bet'
//import TruffleContract from 'truffle-contract'
const contract = require('truffle-contract')

export default {
  name: 'Bets',
  components: {
    Bet
  },
  props: ['web3', 'provider', 'account', 'balance'],
  data () {
    return {
      headline: 'Bets',
      numBets: 0,
      betRegistry: {
        address: '0xb09e08f2d8ba53ff54c464f7ec1135a92faea937',
        instance: null
      },
      betContract: null
    }
  },
  methods: {
    initBetRegistry () {  
      let betRegistryArtifact = require('../../../../backend/build/contracts/BetRegistry.json')
      //console.log(betRegistryArtifact)
      let betRegistryContract = contract(betRegistryArtifact)
      //console.log(betRegistryContract)
      //fixTruffleContractCompatibilityIssue(betRegistryContract)

      betRegistryContract.setProvider(this.provider)
      //console.log(betRegistryContract)
      this.betRegistry.instance = betRegistryContract.at(this.betRegistry.address)
      //console.log(this.betRegistry.instance)
    },
    prepareBets () {
      // get bets from betregistry
      this.betRegistry.instance.nextIndex.call().then(nb => {
        this.numBets = Number(nb)
      })
      

      var betArtifact = require('../../../../backend/build/contracts/Bet.json')
      this.betContract = contract(betArtifact)
      this.betContract.setProvider(this.provider)
    },
    fixTruffleContractCompatibilityIssue (contract) {
      if (typeof contract.currentProvider.sendAsync !== "function") {
          contract.currentProvider.sendAsync = function() {
              return contract.currentProvider.send.apply(
                  contract.currentProvider, arguments
              );
          };
      }
      return contract;
    }
  },
  created () {
    this.initBetRegistry()
    this.prepareBets()
  },
}
</script>



