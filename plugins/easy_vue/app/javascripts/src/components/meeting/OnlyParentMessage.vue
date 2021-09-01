<template>
  <div class="parent-message">
    <p>
      {{ translations.label_info_big_recurring_edit_parent }}
    </p>
    <div class="vue-modal__button-panel">
      <button type="button" class="button-positive" @click="goToParent">
        {{ translations.button_open_parent }}
      </button>
      <button type="button" class="button" @click="$emit('onBlur')">
        {{ translations.button_stay_here }}
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: "OnlyParentMessage",
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
    goToParent() {
      this.$emit("onBlur", {
        func: ctx => {
          ctx.openNewModal(this.entity.easyRepeatParent.id);
        }
      });
    }
  }
};
</script>
