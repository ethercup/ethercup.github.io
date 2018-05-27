<template>
  <p>
    <slot></slot>
  </p>
</template>

<script>
export default {
  name: 'Success'
}
</script>

<style scoped>
p {
  font-style: italic;
  color: rgb(111, 175, 38);
}
</style>