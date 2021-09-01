<template>
  <span class="editable-input__wrapper l__w--auto">
    <select v-model="day" class="l__w--auto" @change="$emit('change', day)">
      <option v-for="i in 7" :key="i" :value="i - 1">
        {{ dayNames[i - 1] }}
      </option>
    </select>
  </span>
</template>

<script>
export default {
  name: "WeekDaysSelect",
  props: {
    weekDayValue: {
      type: [String, Number],
      default: () => ""
    },
    translations: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      day: this.weekDayValue,
      dayNames: JSON.parse(this.translations.date_day_names)
    };
  }
};
</script>
