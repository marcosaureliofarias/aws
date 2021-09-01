<template>
  <section id="mails" :class="bem.ify(bem.block, 'section')">
    <h2 :class="bem.ify(bem.block, 'heading') + ' icon--group'">
      {{ translations.field_mails }}
    </h2>
    <div class="entity-array labeled">
      <span v-for="(mail, i) in mailsSplit" :key="i">
        {{ mail }}
      </span>
    </div>
  </section>
</template>

<script>
export default {
  name: "Mails",
  props: {
    mails: {
      type: String,
      default: () => ""
    },
    bem: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    }
  },
  computed: {
    mailsSplit() {
      return this.$props.mails.split(",");
    }
  }
};
</script>

<style scoped></style>
