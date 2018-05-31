<template>
  <p class="green italic">
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
  margin-bottom: 1.5rem;
}
</style>