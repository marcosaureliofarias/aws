<template>
  <div :class="bem.ify(block, element)">
    <p :class="bem.ify(block, `${element}-text`)">
      {{ text }}
    </p>
    <div>
      <button
        :class="
          `${bem.ify(block, `${element}-button-confirm`)} button-mini-positive excluded`
        "
        @click.prevent="$emit('confirmed', true)"
      >
        {{ translations.button_confirm }}
      </button>
      <button
        :class="`${bem.ify(block, `${element}-button-cancel`)} button-mini excluded`"
        @click.prevent="$emit('confirmed', false)"
      >
        {{ translations.button_cancel }}
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: "Confirm",
  props: {
    bem: Object,
    translations: Object,
    confirmText: String
  },
  data() {
    return {
      text:
        this.$props.confirmText || this.$props.translations.text_are_you_sure,
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  }
};
</script>

<style lang="scss" scoped></style>
