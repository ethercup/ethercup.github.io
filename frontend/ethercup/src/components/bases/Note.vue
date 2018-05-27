<template>
  <p>
    <slot></slot>
  </p>
</template>

<script>
export default {
  name: 'Note'
}
</script>

<style scoped>
p {
  font-size: 1.2rem;
  line-height: 1.3;
}
</style>