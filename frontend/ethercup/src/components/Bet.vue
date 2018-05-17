<template>
  <li class="a bet">
    <h2>{{ msg }}</h2>




    <button v-on:click="placeBet($index)">Bet!</button>
  </li>
</template>




<script>
//import Bet from './Bet'

export default {
  name: 'Bet',
  data () {
    return {
      msg: 'this is a bet'
    }
  },
  methods: {
    placeBet: function () {
      this.msg = "tadaaa" 
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