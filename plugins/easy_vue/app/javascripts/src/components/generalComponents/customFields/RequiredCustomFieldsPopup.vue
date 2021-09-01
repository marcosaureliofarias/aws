<template>
  <div
    ref="popup"
    tabindex="1"
    class="l__w--full excluded"
    style="outline: none"
  >
    <h4 class="vue-modal__heading--popup popup-heading">
      Fill required custom fields first please
    </h4>
    <GenericCf
      v-for="cf in requiredFieldsToFill"
      :id="cf.customField.id"
      :key="cf.customField.id"
      :class="
        `${bem.block}__custom-field ${bem.block}__custom-field--in-popup ${bem.block}__attribute`
      "
      :style="cf.customField.fieldFormat === 'bool' ? 'display: none' : ''"
      :block="bem.block"
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
      :no-save="true"
      :with-loading="false"
      @cf-change="setCFValue($event, cf)"
    />
    <div class="vue-modal__button-panel">
      <button
        type="button"
        class="button-positive"
        :disabled="!allReqFieldsFilled"
        @click="onSave"
      >
        {{ translations.button_save }}
      </button>
      <button type="button" class="button" @click="$emit('onBlur')">
        {{ translations.button_cancel }}
      </button>
    </div>
  </div>
</template>

<script>
import GenericCf from "./GenericCf";
import customValuesQuery from "../../../graphql/customValuesQuery";

export default {
  name: "RequiredCustomFieldsPopup",
  components: { GenericCf },
  props: {
    bem: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    },
    task: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      requiredCustomFieldsValues: {}
    };
  },
  computed: {
    requiredFieldsToFill() {
      return this.$store.state.issue.requiredCustomValuesToFill;
    },
    textile() {
      if (!this.$store.state.allSettings) return false;
      return this.$store.state.allSettings.text_formatting !== "HTML";
    },
    allReqFieldsFilled() {
      const filledValuesCount = Object.values(
        this.requiredCustomFieldsValues
      ).reduce((acc, curVal) => {
        return curVal ? acc + 1 : acc;
      }, 0);
      return (
        filledValuesCount === Object.keys(this.requiredFieldsToFill).length
      );
    }
  },
  mounted() {
    this.$refs.popup.focus();
    this.fillValues();
  },
  methods: {
    setCFValue(val, cf) {
      this.requiredCustomFieldsValues = {
        ...this.requiredCustomFieldsValues,
        [cf.customField.id]: val
      };
    },
    fillValues() {
      const cfsToFill = this.$store.state.issue.requiredCustomValuesToFill;
      cfsToFill.forEach(cf => {
        if (cf.customField.fieldFormat === "bool") {
          this.requiredCustomFieldsValues = {
            ...this.requiredCustomFieldsValues,
            [cf.customField.id]: cf.value ? "1" : "0"
          };
        }
      });
    },
    async fetchCustomValues() {
      const payload = {
        name: "customValues",
        apolloQuery: {
          query: customValuesQuery,
          variables: {
            id: this.task.id
          }
        },
        level: "issue"
      };
      await this.$store.dispatch("fetchIssueValue", payload);
    },
    async onSave() {
      const req = await fetch(
        `${window.urlPrefix}/issues/${this.task.id}.json`,
        {
          method: "PATCH",
          body: JSON.stringify({
            issue: {
              custom_field_values: this.requiredCustomFieldsValues
            }
          }),
          headers: {
            "Content-Type": "application/json"
          }
        }
      );

      if (req.ok) {
        await this.fetchCustomValues();
        this.$store.state.issue.requiredCustomValuesToFill = {};
        this.$store.state.refreshCustomFields += 1;
        await this.$nextTick();
        this.$emit("onBlur");
        return;
      }
      this.$store.commit("setNotification", {
        err: { message: this.translations.notice_failed_to_update }
      });
    }
  }
};
</script>

<style scoped></style>
