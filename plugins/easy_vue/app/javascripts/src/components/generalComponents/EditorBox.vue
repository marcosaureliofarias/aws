<template>
  <div :class="bem.ify(block, 'editorbox') + ` ${inputStateClass}`">
    <div v-if="!showEditor" class="vue-modal__notice-addData no-hover">
      <ul>
        <li>
          {{ translations.notice_modal_textile_formatting }}
        </li>
      </ul>
    </div>
    <textarea
      v-else-if="!showCkEditor"
      v-model="input"
      :placeholder="config.placeholder"
      @input="changed"
    />
    <Ckeditor
      v-else
      :id="config.id"
      v-model="input"
      :class="config.classes"
      :toolbar="editorParams('toolbar', 'Extended')"
      :language="editorParams('language', 'en')"
      :startup-focus="editorParams('startupFocus', false)"
      :remove-plugins="editorParams('removePlugins', 'codesnippet')"
      @input="changed"
    />
    <div
      v-show="config.showButtons"
      :class="bem.ify(block, 'editorbox') + '-buttons'"
    >
      <button
        :class="saveButtonClass"
        :disabled="!valueChanged"
        @click="saveUpdates"
      >
        {{ translations.button_save }}
      </button>
      <button class="button" @click="cancelEdit">
        {{ translations.button_cancel }}
      </button>
      <slot />
    </div>
  </div>
</template>

<script>
import Ckeditor from "./Ckeditor";
export default {
  name: "EditorBox",
  components: {
    Ckeditor
  },
  props: {
    config: Object,
    value: {
      type: String,
      default: () => ""
    },
    translations: Object,
    bem: Object,
    lazy: {
      type: Boolean,
      default: () => false
    },
    textile: {
      type: Boolean,
      default: () => false
    },
    textFormatting: {
      type: [Boolean, String],
      default: () => false
    },
    clearAfterSave: {
      type: Boolean,
      default: () => true
    },
    wipNotify: {
      type: Boolean,
      default: () => true
    },
    required: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      wip: false,
      inputValue: "",
      initialValue: this.$props.value || "",
      block: this.$props.bem.block,
      timerInput: null,
      isCkSettingsOptions:
        window.hasOwnProperty("ckSettings") &&
        window.ckSettings.hasOwnProperty("options")
    };
  },
  computed: {
    input: {
      get() {
        return this.$props.value || "";
      },
      set(value) {
        this.inputValue = value;
      }
    },
    conf() {
      return this.$props.config;
    },
    valueChanged() {
      if (!this.input && this.required) return false;
      const changedValue = this.initialValue.trim() !== this.input.trim();
      const changed = this.conf.changed ? this.conf.changed : false;
      if (this.$props.wipNotify) {
        this.wipActivated(changedValue);
      }
      return changedValue || changed;
    },
    saveButtonClass() {
      return {
        "button-positive": this.valueChanged,
        button: !this.valueChanged
      };
    },
    inputStateClass() {
      return !this.input ? "" : "u-hasValue";
    },
    showEditor() {
      if (!this.$props.textFormatting) return !this.$props.textile;
      if (this.$props.textFormatting === "full" && this.$props.textile) {
        return false;
      }
      return true;
    },
    showCkEditor() {
      if (!this.$props.textFormatting) return !this.$props.textile;
      if (this.$props.textFormatting === "no-formated") return false;
      return true;
    }
  },
  methods: {
    async saveUpdates() {
      await this.$emit("save-updates", this.inputValue);
      this.wipActivated(false);
      if (!this.$props.clearAfterSave) {
        this.initialValue = this.inputValue;
      }
    },
    changed() {
      if (this.$props.lazy) {
        if (this.timerInput) {
          clearTimeout(this.timerInput);
          this.timerInput = null;
        }
        this.timerInput = setTimeout(() => {
          this.$emit("valueChanged", this.inputValue);
        }, 800);
      } else {
        this.$emit("valueChanged", this.inputValue);
      }
    },
    cancelEdit() {
      this.$emit("cancel-edit", this.initialValue);
    },
    editorParams(type, defaultData) {
      if (this.$props.config.hasOwnProperty(type)) {
        return this.$props.config[type];
      }
      const ckSettingsOptions =
        this.isCkSettingsOptions &&
        window.ckSettings.options.hasOwnProperty(type);

      return ckSettingsOptions ? window.ckSettings.options[type] : defaultData;
    }
  }
};
</script>

<style lang="scss" scoped></style>
