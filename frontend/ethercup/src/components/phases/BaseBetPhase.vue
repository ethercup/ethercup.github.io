<template>
  <div>
    <div class="header">
      <slot name="header"></slot>
    </div>
    <div class="main">
      <slot name="main"></slot>
    </div>
    <div class="times">
      <slot name="times"></slot>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'BaseBetPhase'
  }

</script>

<style scoped>
.header {
  margin-bottom: 20px;
  font-style: italic;
  font-size: 1.8rem;
}
.main {

}
.times {
  margin: 20px 0px;
}
</style>