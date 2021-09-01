<template>
  <div :class="`${block}__tags`">
    <a
      v-for="tag in tags"
      :key="tag.id"
      class="tag tag--no-background tag--multiline"
      :href="tag[tagsPath]"
      target="_blank"
    >
      {{ tag[label] }}
    </a>
  </div>
</template>

<script>
export default {
  name: "Tags",
  props: {
    block: String,
    tags: Array,
    tagsPath: String,
    label: {
      type: String,
      default() {
        return "name";
      }
    }
  }
};
</script>

<style scoped></style>
