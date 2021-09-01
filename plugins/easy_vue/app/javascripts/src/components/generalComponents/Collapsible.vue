<template>
  <div :class="`${block}__collapsible-wrapper ${showBody ? 'open' : ''}`">
    <div :class="`${block}__collapsible-header`" @click="showBody = !showBody">
      <span class="collapsible-close icon-close" />
      <slot name="header" />
    </div>
    <slot v-if="showBody" name="body" />
  </div>
</template>

<script>
export default {
  name: "Collapsible",
  props: {
    block: {
      type: String,
      default: () => ""
    },
    defaultOpened: {
      type: Boolean,
      default: () => true
    }
  },
  data() {
    return {
      showBody: this.defaultOpened
    };
  }
};
</script>

<style scoped></style>
