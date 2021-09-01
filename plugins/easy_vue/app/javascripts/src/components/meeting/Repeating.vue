<template>
  <div class="vue-modal__repeating">
    <div
      class="vue-modal__repeating-container"
    >
      <AdvancedRepeating
        :entity="entity"
        :easy-repeat-settings="mergedSettings"
        :translations="translations"
        :bem="bem"
      />
    </div>
    <div class="vue-modal__button-panel">
      <button type="button" class="button-positive" @click="onSave">
        {{ translations.button_save }}
      </button>
      <button type="button" class="button" @click="$emit('onBlur')">
        {{ translations.button_cancel }}
      </button>
      <button
        v-if="entity.easyIsRepeating"
        class="button"
        type="button"
        @click="removeRepeating"
      >
        {{ translations.button_easy_is_not_easy_repeating }}
      </button>
    </div>
  </div>
</template>

<script>
import AdvancedRepeating from "./AdvancedRepeating";

export default {
  name: "Repeating",
  components: {
    AdvancedRepeating
  },
  props: {
    bem: Object,
    translations: Object,
    entity: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      mergedSettings: {
        ...{
          simple_period: "custom",
          period: "monthly",
          daily_option: "each",
          daily_each_x: 1,
          daily_work_x: 1,
          week_days: [],
          monthly_option: "xth",
          monthly_day: 1,
          monthly_custom_order: "1",
          monthly_custom_day: "0",
          monthly_period: 1,
          yearly_option: "date",
          yearly_month: "1",
          yearly_day: 1,
          yearly_custom_order: "1",
          yearly_custom_day: "0",
          yearly_custom_month: "1",
          yearly_period: 1,
          create_now: "all",
          create_now_count: 10,
          easy_next_start: "",
          endtype: "endless",
          endtype_count_x: "",
          end_date: "",
          repeat_hour: "",
          big_recurring: this.entity.big_recurring
        },
        ...this.entity.easyRepeatSettings
      }
    };
  },
  methods: {
    onSave() {
      // easy_next_start needs to be saved separately, not in easy_repeat_settings object
      this.mergedSettings.simple_period = "custom";
      const data = {
        easy_next_start: this.mergedSettings.easy_next_start,
        easy_repeat_settings: this.mergedSettings,
        easy_is_repeating: !!this.mergedSettings.simple_period,
        big_recurring: this.mergedSettings.big_recurring
      };
      this.$emit("data-change", {
        payload: data
      });
      this.$emit("onBlur");
    },
    removeRepeating() {
      const data = {
        easy_repeat_settings: {
          simple_period: ""
        },
        easy_is_repeating: false,
        big_recurring: false
      };
      this.$emit("data-change", {
        payload: data
      });
      this.$emit("onBlur");
    }
  }
};
</script>

<style scoped></style>
