<template>
  <Attribute :id="id" :bem="bem" :data="inlineInputData" />
</template>

<script>
import Attribute from "../generalComponents/Attribute";
export default {
  name: "PopUpAttribute",
  components: {
    Attribute
  },
  props: {
    bem: {
      type: Object,
      default: () => {}
    },
    data: {
      type: Object,
      default: () => {}
    },
    id: {
      type: [String, Number],
      default: () => ""
    }
  },
  data() {
    return {
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    propsData() {
      return this.$props.data;
    },
    inlineInputData() {
      return {
        labelName: this.propsData.labelName,
        value: this.propsData.value,
        inputType: this.propsData.inputType || "autocomplete",
        optionsArray: false,
        withSpan: true,
        unit: this.propsData.unit,
        editable: this.propsData.editable,
        showPopUp: true,
        onClick: (id, name, e) => {
          if (!this.propsData.editable) return;
          const componentName = this.propsData.component;
          this.$emit("open-popup", { componentName, e });
        }
      };
    }
  }
};
</script>

<style scoped></style>
