<template>
  <div :class="bem.ify(block, element)">
    <h4 :class="bem.ify(bem.block, `${element}-heading`) + ' popup-heading'">
      {{ options.heading }}
    </h4>
    <input v-model="duration" type="text" style="margin-bottom: 10px" />
    <select v-model="durationUnit" name="duration_units">
      <option v-for="(unit, i) in options.units" :key="i">
        {{ unit.value }}
      </option>
    </select>
    <div class="vue-modal__button-panel">
      <button type="button" class="button-positive" @click="saveDuration">
        {{ translations.button_save }}
      </button>
      <button type="button" class="button" @click="$emit('onBlur')">
        {{ translations.button_cancel }}
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: "Duration",
  props: {
    bem: Object,
    translations: Object,
    options: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      duration: this.$props.options.duration.value,
      durationUnit: this.$props.options.duration.unit.value,
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  methods: {
    saveDuration() {
      const payload = {
        changing: {
          easy_duration: +this.duration,
          easy_duration_time_unit: this.getUnitKey(this.durationUnit)
        }
      };
      this.$emit("confirmed", payload);
    },
    getUnitKey(unitValue) {
      const key = this.options.units.find(unit => unit.value === unitValue).key;
      if (!key) return "";
      return key;
    }
  }
};
</script>

<style lang="scss" scoped></style>
