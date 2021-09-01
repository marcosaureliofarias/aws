<template>
  <div class="repeating-delete">
    <h4>{{ translations.label_delete_repeating_events }}</h4>
    <div>
      <p v-if="showCurrent">
        <label>
          <input v-model="toDelete" type="radio" value="current" />
          {{ translations.label_current_event }}
        </label>
      </p>
      <template v-if="entity.easyIsRepeating || entity.easyRepeatParent">
        <p v-if="!entity.bigRecurring">
          <label>
            <input v-model="toDelete" type="radio" value="follow" />
            {{ translations.label_current_and_following_events }}
          </label>
        </p>
        <p>
          <label>
            <input v-model="toDelete" type="radio" value="all" />
            {{ translations.label_all_events }}
          </label>
        </p>
      </template>
    </div>
    <div class="vue-modal__button-panel">
      <button type="button" class="button-positive" @click="onSave">
        {{ translations.button_delete }}
      </button>
      <button type="button" class="button" @click="$emit('onBlur')">
        {{ translations.button_cancel }}
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: "DeleteRepeating",
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
  data() {
    return {
      toDelete: this.showCurrent() ? "current" : "all"
    };
  },
  methods: {
    showCurrent() {
      const meeting = this.entity;
      const parent = meeting.easyRepeatParent;
      const bigRecurring = meeting.bigRecurring;
      const repeating = meeting.easyIsRepeating;

      if (bigRecurring && !parent && !repeating) {
        return true;
      } else if (!bigRecurring) {
        return true;
      }
      return false;
    },
    onSave() {
      let suffix = this.buildSuffix();
      this.makeDeleteRequest(suffix);
    },
    buildSuffix() {
      switch (this.toDelete) {
        case "follow":
          return "?current_and_following=1";
        case "all":
          return "?repeating=1";
        default:
          return "";
      }
    },
    async makeDeleteRequest(suffix) {
      await fetch(`/easy_meetings/${this.entity.id}.json${suffix}`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" }
      });
      this.$emit("onBlur", {
        func: ctx => {
          ctx.$refs["modal-wrapper"].closeModal();
        }
      });
    }
  }
};
</script>

<style scoped></style>
