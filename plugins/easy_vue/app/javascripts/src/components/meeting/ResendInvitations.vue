<template>
  <div class="parent-message">
    <p>
      {{ translations.label_resend_invitations }}
    </p>
    <div class="vue-modal__button-panel">
      <button
        type="button"
        class="button-positive"
        @click="resendInvitations(true)"
      >
        {{ translations.general_text_yes }}
      </button>
      <button type="button" class="button" @click="resendInvitations(false)">
        {{ translations.general_text_no }}
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: "ResendInvitations",
  props: {
    entity: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    }
  },
  methods: {
    resendInvitations(shouldSend) {
      this.$emit("onBlur", shouldSend);
    }
  }
};
</script>

<style scoped></style>
