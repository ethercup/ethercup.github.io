<template>
  <p>
    <slot></slot>
  </p>
</template>

<script>
export default {
  name: 'Warning'
}
</script>

<style scoped>
p {
  font-style: italic;
  color: red;
}
</style>