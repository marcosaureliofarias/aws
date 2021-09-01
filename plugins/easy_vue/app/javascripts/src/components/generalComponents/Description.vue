<template>
  <section id="description_anchor" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading') + ' icon--issue'">
      {{ translations.field_description }}
    </h2>
    <div
      v-if="editorInput && !editorShow"
      :class="`${bem.ify(block, 'description')} ${workflowPermClass}`"
      @click="editorSwitch()"
      v-html="editorInput"
    />
    <EditorBox
      v-if="editorShow && permissionEdit"
      :config="editorConfig"
      :value="editorInput"
      :translations="translations"
      :textile="textile"
      :bem="bem"
      @valueChanged="changeDescription($event)"
      @save-updates="saveAndClose($event)"
      @cancel-edit="clearChanges()"
    />
    <div
      v-else-if="!editorInput && !editorShow"
      :class="bem.ify(block, 'description')"
      @click="editorSwitch()"
    >
      <div class="vue-modal__notice-addData" :class="permissionClasses">
        <ul>
          <li>{{ translations.text_modal_description }}</li>
          <li v-if="permissionEdit">
            {{ translations.text_modal_description_add }}
          </li>
        </ul>
      </div>
    </div>
  </section>
</template>

<script>
import EditorBox from "./EditorBox";

export default {
  name: "Description",
  components: {
    EditorBox
  },
  props: {
    bem: Object,
    entity: Object,
    editable: {
      type: Boolean,
      default() {
        return false;
      }
    },
    textile: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      editorConfig: {
        placeholder: "Description",
        edit: false,
        clearOnSave: false,
        showButtons: true,
        id:"description",
        startupFocus: true
      },
      translations: this.$store.state.allLocales,
      editorInput: this.$props.entity ? this.$props.entity.description : "",
      editorShow: false,
      buttonChange: false,
      block: this.$props.bem.block,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase(),
      permissionClasses: this.permissionEdit ? "" : "no-hover"
    };
  },
  computed: {
    permissionEdit() {
      return this.$props.editable && this.workFlowChangable("description");
    },
    workflowPermClass() {
      return this.permissionEdit ? "editable-wrapper" : "no-hover";
    }
  },
  methods: {
    editorSwitch() {
      if (!this.permissionEdit) return;
      this.editorShow = !this.editorShow;
    },
    async saveAndClose(inputValue) {
      this.editorInput = inputValue;
      this.editorShow = false;
      this.$emit("save", inputValue);
    },
    clearChanges() {
      this.editorInput = this.$props.entity.description;
      this.wipActivated(false);
      this.editorSwitch();
    },
    changeDescription(value) {
      this.editorInput = value;
    }
  }
};
</script>
