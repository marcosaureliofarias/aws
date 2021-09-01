<template>
  <section id="custom_fields" :class="bem.ify(block, 'section')">
    <div v-if="cfVisible" :key="refreshCustomFields">
      <div
        v-for="(groupedCfs, key) in groupedCustomFields"
        :key="key"
        class="vue-modal__custom-fields"
      >
        <legend
          v-if="key !== 'default'"
          :class="`${block}__custom-field-label`"
        >
          {{ key }}
        </legend>
        <div v-if="groupedCfs[0].length" class="vue-modal__custom-fields--left">
          <GenericCf
            v-for="cf in groupedCfs[0]"
            :id="cf.customField.id"
            :key="cf.customField.id"
            :class="`${block}__custom-field ${block}__attribute`"
            :block="block"
            :bem="bem"
            :value="cf.value"
            :formatted-value="cf.formattedValue"
            :default-value="cf.customField.defaultValue"
            :multiple="cf.customField.multiple"
            :link-values-to="cf.customField.formatStore.url_pattern"
            :required="cf.customField.isRequired"
            :label="cf.customField.name"
            :field-format="cf.customField.fieldFormat"
            :description="cf.customField.description"
            :translations="translations"
            :editable="cf.editable"
            :possible-values="cf.possibleValues"
            :tag-style="cf.customField.formatStore.edit_tag_style"
            :task-id="task.id"
            :text-formatting="cf.customField.formatStore.text_formatting"
            :textile="textile"
            :popup-on-click="popupOnCFClick"
            @open-required-popup="$emit('open-required-popup')"
          />
        </div>
        <div
          v-if="groupedCfs[1].length"
          class="vue-modal__custom-fields--right"
        >
          <GenericCf
            v-for="cf in groupedCfs[1]"
            :id="cf.customField.id"
            :key="cf.customField.id"
            :class="`${block}__custom-field ${block}__attribute`"
            :block="block"
            :bem="bem"
            :value="cf.value"
            :formatted-value="cf.formattedValue"
            :default-value="cf.customField.defaultValue"
            :multiple="cf.customField.multiple"
            :link-values-to="cf.customField.formatStore.url_pattern"
            :required="cf.customField.isRequired"
            :label="cf.customField.name"
            :field-format="cf.customField.fieldFormat"
            :description="cf.customField.description"
            :translations="translations"
            :editable="cf.editable"
            :possible-values="cf.possibleValues"
            :tag-style="cf.customField.formatStore.edit_tag_style"
            :task-id="task.id"
            :text-formatting="cf.customField.formatStore.text_formatting"
            :textile="textile"
            :popup-on-click="popupOnCFClick"
            @open-required-popup="$emit('open-required-popup')"
          />
        </div>
      </div>
    </div>
    <transition appear name="flash">
      <div class="custom-fields__button-panel">
        <button
          v-if="!cfVisible"
          type="button"
          class="button icon-add"
          @click="cfVisible = true"
        >
          {{ translations.button_show_custom_fields }}
        </button>
        <button
          v-else
          class="button icon-remove"
          type="button"
          @click="cfVisible = false"
        >
          {{ translations.button_hide_custom_fields }}
        </button>
      </div>
    </transition>
  </section>
</template>

<script>
import GenericCf from "../generalComponents/customFields/GenericCf";
export default {
  name: "CustomFields",
  components: { GenericCf },
  props: {
    customFields: {
      type: Array,
      default: () => []
    },
    bem: {
      type: Object,
      default: () => {}
    },
    block: {
      type: String,
      default: () => ""
    },
    translations: {
      type: Object,
      default: () => {}
    },
    task: {
      type: Object,
      default: () => {}
    },
    textile: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      cfVisible: false
    };
  },
  computed: {
    groupedCustomFields() {
      let groupedCustomFields = {};
      this.customFields.forEach(cf => {
        const easyGroup = cf.customField.easyGroup;
        const group = easyGroup && easyGroup.name ? easyGroup.name : "default";
        if (!groupedCustomFields[group]) groupedCustomFields[group] = [];
        groupedCustomFields[group].push(cf);
      });
      // we need to split data to two halves
      this.splitGroupsToTwoHalves(groupedCustomFields);
      return groupedCustomFields;
    },
    requiredCfToFillCount() {
      const requiredCFs = this.$store.state.issue.requiredCustomValuesToFill;
      return requiredCFs && requiredCFs.length;
    },
    popupOnCFClick() {
      return !!(this.requiredCfToFillCount && this.requiredCfToFillCount > 1);
    },
    refreshCustomFields() {
      return this.$store.state.refreshCustomFields;
    }
  },
  created() {
    this.$set(this.$store.state, "refreshCustomFields", 0);
  },
  methods: {
    splitGroupsToTwoHalves(groupedCustomFields) {
      const isEmpty = Object.keys(groupedCustomFields).length;
      if (!isEmpty) return groupedCustomFields;
      for (const key in groupedCustomFields) {
        if (!groupedCustomFields.hasOwnProperty(key)) return;
        const group = groupedCustomFields[key];
        const half = Math.ceil(group.length / 2);
        const left = group.slice(0, half);
        const right = group.slice(half, group.length);
        groupedCustomFields[key] = [left, right];
      }
    }
  }
};
</script>

<style scoped></style>
