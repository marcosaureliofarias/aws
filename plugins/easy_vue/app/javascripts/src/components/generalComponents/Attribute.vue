<template>
  <li
    :class="`${bem.ify(block, element, inlineInputData.name)}`"
    @click="onClick($event, id, inlineInputData.fetchItemName)"
  >
    <InlineInput
      v-if="
        inlineInputData.optionsArray.length || !inlineInputData.optionsArray
      "
      :id="id"
      ref="attribute-input"
      :data="inlineInputData"
      :date-prop="inlineInputData.date"
      :value="inlineInputData.value"
      :class="permissionClasses"
      :options-array="inlineInputData.optionsArray"
      :multiple="multiple"
      :lazy="lazy"
      :error-messages="errorMessages"
      :error-type="errorType"
      :with-loading="data.withLoading"
      :required="required"
      @child-value-change="sendValueToParent"
      @child-value-input="inputChanged"
    />
    <span
      v-else
      class="editable-input__wrapper editable-input__wrapper--static no-hover"
      :class="permissionClasses"
    >
      {{ inlineInputData.value }}
    </span>
    <label :class="`${bem.ify(block, `${element}-label`)}`">
      {{ inlineInputData.labelName }}
    </label>
    <span :class="`${bem.ify(block, `${element}-bar`)}`" />
  </li>
</template>

<script>
import InlineInput from "./InlineInput";
export default {
  name: "Attribute",
  components: {
    InlineInput
  },
  props: {
    bem: Object,
    data: Object,
    id: [Number, String],
    multiple: {
      type: Boolean,
      default: () => false
    },
    lazy: {
      type: Boolean,
      default: () => false
    },
    errorMessages: {
      type: Array,
      default: () => null
    },
    errorType: {
      type: String,
      default: () => null
    },
    required: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase(),
      modifier: this.$props.bem.element
    };
  },
  computed: {
    permissionClasses() {
      return this.data.editable ? "" : "no-hover";
    },
    inlineInputData() {
      return this.$props.data;
    }
  },
  created() {
    this.$props.data;
  },
  methods: {
    onClick(e, id, name) {
      if (!this.$props.data.onClick) return;
      this.$props.data.onClick(id, name, e);
    },
    onBlur(id) {
      if (!this.$props.data.onBlur) return;
      this.$props.data.onBlur(id);
    },
    focusAttribute() {
      this.$refs["attribute-input"].setEdit(true);
    },
    sendValueToParent(value) {
      this.$emit("child-value-change", value);
    },
    inputChanged(value) {
      this.$emit("child-value-input", value);
    }
  }
};
</script>

<style scoped></style>
