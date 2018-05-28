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
  margin-bottom: 1.5rem;
}
</style>