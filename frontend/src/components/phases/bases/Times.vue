<template>
  <p class="italic">
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
  margin: 20px 0px;
}
</style>