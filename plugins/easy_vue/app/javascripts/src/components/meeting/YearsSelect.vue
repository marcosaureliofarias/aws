<template>
  <span class="editable-input__wrapper l__w--auto">
    <select v-model="year" @change="$emit('change', year)">
      <option v-for="i in 12" :key="i" :value="i">
        {{ monthNames[i] }}
      </option>
    </select>
  </span>
</template>

<script>
export default {
  name: "YearsSelect",
  props: {
    yearValue: {
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
      year: this.yearValue,
      monthNames: JSON.parse(this.translations.date_standalone_month_names)
    };
  }
};
</script>
