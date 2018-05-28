<template>
  <p>
    <slot></slot>
  </p>
</template>

<script>
export default {
  name: 'Times'
}
</script>

<style scoped>
p {
  font-style: italic;
  margin: 20px 0px;
}
</style>