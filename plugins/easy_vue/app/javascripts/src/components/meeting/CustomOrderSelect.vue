<template>
  <span class="editable-input__wrapper l__w--auto">
    <select v-model="customOrder" class="l__w--auto" @change="$emit('change', customOrder)">
      <option v-for="i in 5" :key="i" :value="i">
        {{ translations[`label_easy_issue_reccuring_monthly_orders_${i}`] }}
      </option>
    </select>
  </span>
</template>

<script>
export default {
  name: "CustomOrderSelect",
  props: {
    customOrderValue: {
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
      customOrder: this.customOrderValue
    };
  }
};
</script>
