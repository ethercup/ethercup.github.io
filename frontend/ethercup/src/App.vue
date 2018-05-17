<template>
  <div id="app">
    <img src="./assets/logo.png">
    <Bets/>
  </div>
</template>

<script>
import Bets from './components/Bets'

export default {
  name: 'App',
  components: {
    Bets
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
