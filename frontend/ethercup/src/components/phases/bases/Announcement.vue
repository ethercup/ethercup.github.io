<template>
  <p>
    <slot></slot>
  </p>
</template>

<script>
export default {
  name: 'Announcement'
}
</script>

<style scoped>
p {
  margin-bottom: 20px;
  font-style: italic;
  font-size: 1.8rem;
}
</style>