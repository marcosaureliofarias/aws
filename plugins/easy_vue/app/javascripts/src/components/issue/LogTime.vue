<template>
  <form ref="log-time__form" :class="formCss">
    <div :class="bem.ify(block, 'form-item')">
      <label :class="bem.ify(block, 'form-item-label', 'required')">
        {{ translations.label_date }}
        <span>*</span>
      </label>
      <datetime
        v-model="date"
        :input-attr="{ name: 'spent_on' }"
        :format="format"
        :lang="datepickerOverrides"
      />
    </div>
    <div :class="bem.ify(block, 'form-item')">
      <label
        :class="bem.ify(block, 'form-item-label', 'required')"
        :title="translations.label_time_entry_tooltip"
      >
        {{ translations.field_hours }}
        <span>*</span>
        <i class="icon icon-help-bubble" />
      </label>
      <input
        v-model="hours"
        name="time_entry[hours]"
        type="text"
        :class="bem.ify(block, 'form-item-value')"
        min="0"
      />
    </div>
    <div :class="commentClass()">
      <label :class="prepareLabelClass({bem, block, required: commentRequired})">
        {{ translations.label_comment }}
        <span v-if="commentRequired">*</span>
      </label>
      <input
        v-if="!spentTimeCKEditor"
        v-model="comment"
        name="time_entry[comments]"
        placeholder="Comment"
        type="text"
        :class="bem.ify(block, 'form-item-value')"
        @input="activeWip"
      />
      <template v-else>
        <input
          v-if="!editorShow"
          type="text"
          :placeholder="translations.label_comment_add"
          :class="bem.ify(block, 'fake-ck__full-width')"
          @focus="editorSwitch()"
        />

        <EditorBox
          v-if="editorShow"
          :config="editorConfig"
          :value="comment"
          :translations="translations"
          :textile="textile"
          :bem="bem"
          @valueChanged="changeComment($event)"
        />
        <input type="hidden" :value="comment" :name="`time_entry[comments]`" />
      </template>
    </div>
    <div :class="bem.ify(block, 'form-item') + ' l__w--half'">
      <label :class="bem.ify(block, 'form-item-label', 'required')">
        {{ translations.field_activity }}
        <span>*</span>
      </label>
      <div v-if="enumerations.length < 4">
        <label v-for="enumeration in enumerations" :key="enumeration.id">
          <input
            v-model="enumerationInput"
            name="time_entry[activity_id]"
            type="radio"
            :value="enumeration.id"
            @change="getCustomFields"
          />
          {{ enumeration.name }}
        </label>
      </div>
      <div v-else>
        <select
          v-model="enumerationInput"
          name="time_entry[activity_id]"
          @change="getCustomFields"
        >
          <option
            v-for="enumeration in enumerations"
            :key="enumeration.id"
            :value="enumeration.id"
          >
            {{ enumeration.name }}
          </option>
        </select>
      </div>
    </div>
    <div v-if="isFeatureEnabled('billable')" :class="billableClass()">
      <label :class="bem.ify(block, 'form-item-label')">
        {{ translations.field_easy_is_billable }}
        <input
          type="hidden"
          name="time_entry[easy_is_billable]"
          :value="billable"
        />
        <input
          v-model="billable"
          type="checkbox"
          name="time_entry[easy_is_billable]"
          :placeholder="translations.field_easy_is_billable"
          :class="bem.ify(block, 'form-item-value')"
        />
      </label>
    </div>
    <div :key="refreshCf" class="log-time__cf-wrapper">
      <GenericCf
        v-for="cf in $props.task.timeEntriesCustomValues"
        :id="cf.customField.id"
        :key="cf.customField.id"
        :name="`time_entry[custom_field_values][${cf.customField.id}]`"
        :class="
          `${bem.block}__custom-field ${bem.block}__custom-field--in-popup ${bem.block}__attribute l__w--half`
        "
        :block="bem.block"
        :bem="bem"
        :value="customValues[cf.customField.id]"
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
        @cf-change="changeCustomField(cf, $event)"
      />
    </div>
    <div :class="bem.ify(block, 'form-actions')">
      <div :class="bem.ify(block, 'form-actions')">
        <button
          v-if="!editTimeEntryValues"
          :class="saveButtonClass"
          :disabled="!canSave"
          @click.prevent="saveTimeEntries"
        >
          {{ translations.button_log_time }}
        </button>
        <template v-else>
          <button class="button" @click.prevent="saveEditation">
            {{ translations.button_save }}
          </button>
          <button class="button" @click.prevent="handleCancel">
            {{ translations.button_cancel }}
          </button>
        </template>
      </div>
    </div>
  </form>
</template>
<script>
import EditorBox from "../generalComponents/EditorBox";
import GenericCf from "../generalComponents/customFields/GenericCf";
import timeEntriesCustomValuesQuery from "../../graphql/timeEntriesCustomValues";
export default {
  name: "LogTime",
  components: {
    EditorBox,
    GenericCf
  },
  props: {
    bem: Object,
    task: Object,
    editTimeEntryPayload: Object,
    editTimeEntry: Boolean,
    block: {
      type: String,
      default() {
        return "";
      }
    },
    textile: {
      type: Boolean,
      default: () => false
    },
    cfValues: {
      type: Object,
      default: () => {}
    },
    activityId: {
      type: String,
      default: () => ""
    }
  },
  data() {
    return {
      hours: "0",
      date: new Date(),
      comment: "",
      translations: this.$store.state.allLocales,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase(),
      enumerations: this.$props.task.project.activitiesPerRole,
      format: this.dateFormatString(),
      currentUser: window.EASY.currentUser.id,
      refreshCf: 0,
      editorConfig: {
        placeholder: "Comment",
        edit: false,
        startupFocus: true,
        clearOnSave: false,
        classes: this.bem.ify(this.block, "form-item-value"),
        showButtons: false,
        id: "logTime"
      },
      editorShow: false,
      billable: !!this.$store.state.allSettings.billable_things_default_state,
      spentTimeCKEditor: this.$store.state.allSettings
        .timelog_comment_editor_enabled,
      datepickerOverrides: {
        formatLocale: {
          firstDayOfWeek: this.getFirstDayOfWeek(),
          firstWeekContainsDate: 4
        }
      },
      customValues: {},
      loading: false,
      enumerationId: ""
    };
  },
  computed: {
    saveButtonClass() {
      return {
        "button-positive": this.canSave,
        button: !this.canSave
      };
    },
    valueChanged() {
      return this.comment !== "";
    },
    canSave() {
      const hours = this.hours.toString();
      const hoursParsed = parseFloat(hours.replace(",", "."));
      return hoursParsed > 0 && this.enumerationInput !== null && !this.loading;
    },
    editTimeEntryValues: {
      get() {
        if (!this.$props.editTimeEntry) return false;
        const editableEntry = this.$props.editTimeEntryPayload.unformattedEntry;
        if (!editableEntry) return false;
        const isPayload = Object.keys(editableEntry).length;
        this.setValues(editableEntry);
        return isPayload;
      }
    },
    formCss() {
      const formClass = `${this.block}__form`;
      return {
        [formClass]: true,
        editing: this.editTimeEntry
      };
    },
    commentRequired() {
      return this.task.timeEntriesCommentRequired;
    },
    enumerationInput: {
      get() {
        return this.$props.activityId;
      },
      set(value) {
        this.enumerationId = value;
      }
    }
  },
  created() {
    this.getCustomFields();
  },
  methods: {
    editorSwitch() {
      this.editorShow = !this.editorShow;
    },
    billableClass() {
      return `${this.bem.ify(this.block, "form-item")} ${this.bem.ify(
        this.block,
        "contextual"
      )} l__w--half`;
    },
    commentClass() {
      const bem = this.bem.ify(this.block, "form-item");
      const width = this.spentTimeCKEditor ? "l__w--full" : "l__w--half";
      return `${bem} ${width}`;
    },
    async saveEditation() {
      const timeEntryID = this.$props.editTimeEntryPayload.id;
      const newStoreTimeEntries = this.patchTimeEntries(timeEntryID);
      const payload = {
        reqBody: this.buildRequestBody(),
        reqType: "patch",
        value: { timeEntries: newStoreTimeEntries },
        url: `${window.urlPrefix}/easy_time_entries/${timeEntryID}.json`,
        name: "timeEntries"
      };
      const saved = await this.$store.dispatch("saveIssueStateValue", payload);
      if (saved) {
        this.resetValues();
        this.$emit("edit-cancel");
      }
    },
    patchTimeEntries(timeEntryID) {
      const storeTimeEntries = this.$store.state.issue.timeEntries;
      return storeTimeEntries.map(timeEntry => {
        if (timeEntry.id === timeEntryID) {
          const copy = { ...timeEntry };
          copy.easyIsBillable = this.billable;
          copy.comments = this.comment;
          copy.hours = this.hours;
          copy.spentOn = this.dateFormatForRequest(this.date, "date");
          return copy;
        }
        return timeEntry;
      }, this);
    },
    setValues(editableEntry) {
      this.hours = editableEntry.hours;
      this.date = new Date(editableEntry.spentOn);
      this.comment = editableEntry.comments;
      this.billable = editableEntry.easyIsBillable;
      this.customValues = this.cfValues;
    },
    resetValues() {
      this.hours = "0";
      this.comment = "";
      this.date = new Date();
      this.customValues = {};
      this.loading = false;
      this.billable = !!this.$store.state.allSettings
        .billable_things_default_state;
      this.customValues = {};
      this.refreshCf += 1;
      const options = {
        name: "wip",
        value: false,
        level: "state"
      };
      this.editorShow = false;
      this.$store.commit("setStoreValue", options);
    },
    buildRequestBody() {
      return {
        issue_id: this.task.id,
        project_id: this.task.project.id,
        user_id: this.currentUser,
        time_entry: {
          hours: this.hours,
          comments: this.comment,
          spent_on: moment(this.date).format("YYYY-MM-DD"),
          activity_id: +this.enumerationInput,
          easy_is_billable: this.billable,
          custom_field_values: this.customValues
        }
      };
    },
    async saveTimeEntries() {
      this.loading = true;
      const payload = {
        reqBody: this.buildRequestBody(),
        reqType: "post",
        url: `${window.urlPrefix}/easy_time_entries.json`
      };
      const saved = await this.$store.dispatch("saveIssueStateValue", payload);
      // we need to fetch timeEntries again to have proper time entry ID for editing purposes
      if (saved) {
        await this.$store.dispatch("fetchTimeEntries");
        this.resetValues();
        return;
      }
      this.loading = false;
    },
    changeCustomField({ customField }, newValue) {
      this.customValues[customField.id] = newValue;
    },
    changeComment(value) {
      this.comment = value;
    },
    activeWip() {
      this.wipActivated(this.comment !== "");
    },
    async getCustomFields() {
      const payload = {
        name: "timeEntriesCustomValues",
        apolloQuery: {
          query: timeEntriesCustomValuesQuery,
          variables: {
            id: this.task.id,
            activityId: +this.enumerationInput
          }
        }
      };
      await this.$store.dispatch("fetchIssueValue", payload);
      this.$emit("activity:change", this.enumerationId);
    },
    handleCancel() {
      this.$emit("edit-cancel");
      this.resetValues();
    }
  }
};
</script>
