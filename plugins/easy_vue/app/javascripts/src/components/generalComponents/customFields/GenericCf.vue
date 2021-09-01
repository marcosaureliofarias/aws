<!--Custom field for types: INTEGER, FLOAT, TEXT, LINK, EMAIL, PERCENT -->
<template>
  <div
    :class="
      `${fieldFormat} ${popupOnClick ? 'cf-multiple-required-editable' : ''}`
    "
    class="vue-modal__attribute"
    @click="onClick"
  >
    <label
      :title="description"
      :class="prepareLabelClass({bem, block, required})"
    >
      {{ label }}
      <span v-if="required">*</span>
      <a
        v-if="linkValuesTo && fieldFormat !== 'link'"
        :href="linkValuesTo"
        target="_blank"
        class="icon icon-relation"
      />
    </label>
    <template v-if="fieldFormat === 'text'">
      <EditorBox
        v-if="showTextEditor"
        :config="editorConfig"
        :value="inputValue"
        :translations="translations"
        :textile="textile"
        :text-formatting="textFormatting || 'no-formated'"
        :bem="bem"
        :required="required"
        :clear-after-save="false"
        @valueChanged="editorValueChanged"
        @save-updates="saveText($event, true)"
        @cancel-edit="clearVal"
      />
      <div
        v-else
        :class="
          `editable ${block}__custom-field--text-wrapper editable-input__wrapper excluded ${longTextRequiredClass}`
        "
        @click="showTextEditor = true"
        v-html="inputValue"
      />
    </template>

    <InlineInput
      v-else
      :value="displayValue"
      :date-prop="displayValue"
      :formatted-value="formattedValueComputed"
      :data="inputData"
      :name="name"
      :searchable="true"
      :options-array="optionsArray"
      :multiple="multiple"
      :class="{ multiple: multiple }"
      :with-loading="withLoading"
      :error-messages="errorMessages"
      :error-type="errorType"
      :translations="translations"
      :required="required"
      @child-value-change="saveText"
    />
    <a
      v-if="showMapsLink"
      :href="`https://maps.google.com/maps?q=${inputValue}`"
      target="_blank"
      :title="translations.button_link_easy_google_map_address"
      class="maps icon-popup"
    />
    <span :class="`${bem.ify(block, `attribute-bar`)}`" />
  </div>
</template>

<script>
import InlineInput from "../InlineInput";
import customField from "../../../graphql/mutations/customFields";
import EditorBox from "../EditorBox";

export default {
  name: "GenericCf",
  components: {
    EditorBox,
    InlineInput
  },
  props: {
    id: {
      type: [String, Number],
      default: null
    },
    name: {
      type: String,
      default: ""
    },
    bem: {
      type: Object,
      default: () => {}
    },
    taskId: {
      type: [String, Number],
      default: null
    },
    label: {
      type: String,
      default: ""
    },
    value: {
      type: [String, Array, Number],
      default: ""
    },
    formattedValue: {
      type: String,
      default: ""
    },
    defaultValue: {
      type: String,
      default: ""
    },
    linkValuesTo: {
      type: String,
      default: ""
    },
    description: {
      type: String,
      default: ""
    },
    required: {
      type: Boolean,
      default: false
    },
    multiple: {
      type: Boolean,
      default: false
    },
    noSave: {
      type: Boolean,
      default: false
    },
    fieldFormat: {
      type: String,
      default: ""
    },
    translations: {
      type: Object,
      default: () => {}
    },
    possibleValues: {
      type: Array,
      default: () => []
    },
    textFormatting: {
      type: String,
      default: () => ""
    },
    tagStyle: {
      type: String,
      default: () => ""
    },
    editable: {
      type: Boolean,
      default: () => false
    },
    textile: {
      type: Boolean,
      default: () => false
    },
    block: {
      type: String,
      default: () => ""
    },
    withLoading: {
      type: Boolean,
      default: () => true
    },
    errorMessages: {
      type: Array,
      default: () => []
    },
    errorType: {
      type: String,
      default: () => null
    },
    popupOnClick: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      inputValue: this.displayValue,
      formattedValueComputed: this.formattedValue,
      transformedPossibleValues: this.shouldTransform(),
      editorConfig: {
        placeholder: "",
        edit: true,
        clearOnSave: true,
        showButtons: !this.noSave,
        startupFocus: false,
        id: `cf_${this.id}`
      },
      showTextEditor: false
    };
  },
  computed: {
    inputData() {
      const inputType = this.getType();
      const withSpan = this.withSpan(inputType);
      return {
        labelName: this.$props.label,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        firstOptionEmpty: !this.required && !this.multiple,
        inputType: inputType,
        filterable: true,
        withSpan: withSpan,
        editable: this.isEditable(),
        link: this.getLink(),
        withLink:
          this.$props.fieldFormat === "link" ||
          this.$props.fieldFormat === "attachment",
        date: this.inputValue,
        unit: this.fieldFormat === "easy_percent" ? "%" : "",
        tagStyle: this.$props.tagStyle
      };
    },
    showMapsLink() {
      const isMapType = this.$props.fieldFormat === "easy_google_map_address";
      return this.inputValue && isMapType;
    },
    optionsArray() {
      if (!this.possibleValues.length) return [];
      let transformedArray = [];
      if (this.transformedPossibleValues) {
        transformedArray = this.possibleValues.map(val => {
          return { value: val[1], name: val[0] };
        });
      } else {
        transformedArray = this.possibleValues;
      }
      return transformedArray;
    },
    longTextRequiredClass() {
      if (!this.value && this.required) {
        return "u-showing required";
      } else {
        return "";
      }
    },
    displayValue() {
      let value = "";
      switch (this.$props.fieldFormat) {
        case "attachment":
        case "list":
          if (this.multiple && !!this.value[0]) {
            value = this.value;
          } else {
            value = this.formattedValue;
          }
          break;
        case "version":
        case "country_select":
        case "user":
        case "enumeration":
          if (!this.multiple) {
            value = this.formattedValue || this.value;
          } else {
            // because backend responds data with string format, we need to map them from possible values
            value = this.mapArrayKeys();
          }

          break;
        case "text":
          value = this.formattedValue;
          break;
        default:
          value = this.value;
          break;
      }
      return value || "";
    },
  },
  methods: {
    async saveText(payload, isEditorBox) {
      let requestValue;

      if (payload.hasOwnProperty("inputValue")) {
        const inputVal = payload.inputValue;
        requestValue =
          inputVal.value !== undefined && inputVal.value !== null
            ? inputVal.value
            : inputVal;
      } else {
        requestValue = payload;
      }
      if (this.transformedPossibleValues && this.multiple) {
        requestValue = requestValue.map(entry => entry.value || entry);
      }

      const isBool = this.fieldFormat === "bool";
      if (isBool && this.tagStyle === "check_box") {
        requestValue = requestValue ? "1" : "0";
      }

      const emailValid = this.validateEmailFormat(payload);
      if (!emailValid) return;

      if (this.$props.noSave) {
        this.$emit("cf-change", requestValue);
        this.inputValue = payload.inputValue;
        this.showTextEditor = false;
        this.formattedValueComputed = requestValue;
        return;
      }
      const mutation = {
        mutationName: "customValueChange",
        apolloMutation: {
          mutation: customField,
          variables: {
            entityId: this.taskId,
            entityType: "Issue",
            customFieldId: this.id,
            value: requestValue
          }
        },
        processFunc: payload.showFlashMessage
      };
      const response = await this.$store.dispatch("mutateValue", mutation);
      const customValueChange = response.data.customValueChange;
      if (customValueChange.errors.length) {
        if (!isEditorBox) return;
        this.$store.commit("setNotification", {
          errors: customValueChange.errors
        });
        return;
      }

      const customValues = this.$store.state.issue.customValues;
      const mappedCf = customValues.map(item => {
        const itemId = item.customField.id;
        const changeItemId = customValueChange.customValue.customField.id;
        return itemId === changeItemId ? customValueChange.customValue : item;
      });

      const options = {
        name: "customValues",
        value: mappedCf,
        level: "issue"
      };
      await this.$store.commit("setStoreValue", options);
      this.$store.state.refreshCustomFields += 1;
    },
    onClick(e) {
      if (!this.popupOnClick) return;
      e.preventDefault();
      e.stopPropagation();
      this.$emit("open-required-popup");
    },
    validateEmailFormat({ inputValue, showFlashMessage }) {
      if (this.inputData.inputType !== "email") return true;
      if (inputValue === "") return true;

      const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      const emailValid = re.test(String(inputValue).toLowerCase());
      if (!emailValid) {
        showFlashMessage("error", ["email is not valid"]);
      }
      this.inputValue = inputValue;
      this.formattedValueComputed = inputValue;
      return emailValid;
    },
    getType() {
      switch (this.$props.fieldFormat) {
        case "list":
        case "country_select":
        case "enumeration":
        case "value_tree":
        case "user":
        case "version":
          return "autocomplete";
        case "bool":
          return "bool";
        default:
          return this.$props.fieldFormat;
      }
    },
    withSpan(inputType) {
      switch (inputType) {
        case "autocomplete":
        case "date":
        case "datetime":
        case "bool":
          return false;
        default:
          return true;
      }
    },
    mapArrayKeys() {
      if(Array.isArray(this.value)) {
        const mappedValues = [];
        this.value.forEach(val => {
          return this.possibleValues.forEach(poss => {
            if (poss[1] === val) {
              mappedValues.push({ value: poss[1], name: poss[0] });
            }
          });
        });
        return mappedValues;
      }
    },
    shouldTransform() {
      if (!this.possibleValues.length) return false;
      return Array.isArray(this.possibleValues[0]);
    },
    clearVal(initValue) {
      this.showTextEditor = false;
      this.inputValue = initValue;
      this.wipActivated(false);
    },
    isEditable() {
      const nonEditableCfs = [
        "easy_lookup",
        "attachment",
        "dependent_list",
        "autoincrement"
      ];
      if (nonEditableCfs.includes(this.$props.fieldFormat)) {
        return false;
      } else {
        return this.$props.editable && !this.popupOnClick;
      }
    },
    getLink() {
      if (this.$props.fieldFormat === "attachment") {
        // Build correct attachment (file) link
        return `${window.urlPrefix}/attachments/${this.$props.value}/${this.$props.formattedValue}`;
      } else if (this.$props.fieldFormat === "link") {
        return this.inputValue?.match("http")
          ? this.inputValue
          : `//${this.inputValue}`;
      }
    },
    editorValueChanged(event) {
      this.inputValue = event;
      if (this.noSave) {
        this.$emit("cf-change", event);
      }
    }
  }
};
</script>

<style scoped></style>