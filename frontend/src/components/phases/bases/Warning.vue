<template>
  <p class="red italic">
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
  margin-bottom: 1.5rem;
}
</style>