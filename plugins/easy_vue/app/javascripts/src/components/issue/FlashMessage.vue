<template>
  <div>
    <span>{{ flashMessage }}</span>
  </div>
</template>

<script>
export default {
  name: "FlaskMessage",
  methods: {
    flashMessage() {
      return "text";
    }
  }
};
</script>

<style scoped></style>
