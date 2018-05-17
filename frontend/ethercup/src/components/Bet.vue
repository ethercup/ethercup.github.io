<template>
  <li class="bet">
    <h2>{{ msg }}</h2>

    {{ data.id }}<br>
    {{ data.apiId }}


    {{ reversedMessage }} <!-- calls cached computed -->
    {{ reversedMessage() }} <!-- calls method -->

    <h1 v-if="ok">Yes</h1>
    <h1 v-else>No</h1>

    <h1 v-show="ok">Hello!</h1> <!-- display:block/none toggling. Is always rendered. v-if is not and is lazy-->

    <template v-if="ok">
      <h1>Title</h1>
      <p>Paragraph 1</p>
      <p>Paragraph 2</p>
    </template>

    <div v-if="Math.random() > 0.5">
      Now you see me
    </div>
    <div v-else>
      Now you don't
    </div>

    <div v-if="type === 'A'">
      A
    </div>
    <div v-else-if="type === 'B'">
      B
    </div>
    <div v-else>
      Not A/B
    </div>

    <!-- Iterating over an array -->
    <ul id="example-2">
      <li v-for="(item, index) in items">
        {{ parentMessage }} - {{ index }} - {{ item.message }}
      </li>
    </ul>

    <!-- v-for has higher priority. On iteration, if is checked for every elemnt -->
    <li v-for="todo in todos" v-if="!todo.isComplete">
      {{ todo }}
    </li>

    <!-- Iterating over properties of an object -->
    <li v-for="(value, key, index) in object">
      [{{ index }}] {{ key }} : {{ value }}
    </li>

    <!-- Iterate n times -->
    <span v-for="n in 10">{{ n }} </span>

    <button v-on:click="placeBet($index)">Bet!</button>
  </li>
</template>




<script>

Vue.component('Bet', {
  props: ['betdata'],
  // data () {
  //   return {
  //     id: 0,
  //     apiId: '111'
  //   }
  // }
  computed: { // will be cached, only changed when base variable changes
    now: function () {
      return Date.now() // only run once, will never update
    },
    fullName: {
      // getter
      get: function () {
        return this.firstName + ' ' + this.lastName
      },
      // setter
      set: function (newValue) {
        var names = newValue.split(' ')
        this.firstName = names[0] // this == data.*
        this.lastName = names[names.length - 1]
      }
    }
  },
  methods: { // not cached. Run every time the method is called
    // a method invocation will always run the function whenever a re-render happens.
    reverseMessage: function () {
      return this.message.split('').reverse().join('')
    },
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
})
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