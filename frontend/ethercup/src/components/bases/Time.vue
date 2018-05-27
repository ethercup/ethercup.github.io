<template>
  <div>
    <slot></slot>
  </div>
</template>

<script>
export default {
  name: 'Time',
  props: ['type']
}
</script>

<style scoped>
div {
  font-style: italic;
}
</style>