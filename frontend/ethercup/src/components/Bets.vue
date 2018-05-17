<template>
  <div class="thebets">
    <h1>{{ headline }}</h1>
    <ul>
      <Bet v-for="bet in bets"/>
    </ul>
  </ul>
  </div>
</template>



<script>
import Bet from './Bet'

export default {
  name: 'Bets',
  data () {
    return {
      headline: 'Bets',
      bets: [
        { text: 'Add some todos' }
      ]
    }
  },
  // hook executed after instance is created
  created: function () {
    console.log('a is: ' + this.a) // this==vm instance
  }
}
</script>
