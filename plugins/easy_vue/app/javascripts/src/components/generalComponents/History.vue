<template>
  <section id="history" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading') + ' icon--comments'">
      {{ translations.label_history }}
    </h2>
    <Activity :activities="activities" :bem="bem" />
  </section>
</template>

<script>
import Activity from "../generalComponents/Activity";
export default {
  name: "History",
  components: {
    Activity
  },
  props: {
    bem: Object,
    activities: Array,
    translations: Object
  },
  data() {
    return {
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  }
};
</script>
