<template>
  <div>
    <div
      :class="{
        'vue-modal__form-step': true,
        'vue-modal__form-step--active': !showProject
      }"
    >
      <Attribute
        ref="subjectInput"
        :data="subjectInput"
        :bem="bem"
        :lazy="true"
        class="vue-modal__attribute--long"
        :required="true"
        @child-value-input="subjectChanged($event)"
      />
    </div>
    <transition name="slide-fade">
      <div
        v-if="showProject"
        :class="{
          'vue-modal__form-step': true,
          'vue-modal__form-step--active': !(showTracker || showSecond)
        }"
      >
        <Attribute
          :bem="bem"
          class="vue-modal__attribute--long"
          :data="projectInput"
          :required="true"
          @child-value-change="mainAttributeChanged($event, 'project')"
        />
      </div>
    </transition>
    <transition name="slide-fade">
      <div
        v-if="showSecond"
        :class="{
          'vue-modal__form-step': true
          // 'vue-modal__form-step--active': !(newIssue.requiredFields.length > 0)
        }"
      >
        <Attribute
          v-if="showSecond"
          :id="newIssue.project.id"
          class="vue-modal__attribute--inline"
          :bem="bem"
          :data="trackerInput"
          :required="true"
          @child-value-change="mainAttributeChanged($event, 'tracker')"
        />
        <Attribute
          v-if="showSecond"
          :id="newIssue.project.id"
          class="vue-modal__attribute--inline"
          :bem="bem"
          :data="statusInput"
          :required="true"
          @child-value-change="mainAttributeChanged($event, 'status')"
        />
        <Attribute
          v-if="showSecond"
          :id="newIssue.project.id"
          class="vue-modal__attribute--inline"
          :bem="bem"
          :data="priorityInput"
          :required="true"
          @child-value-change="mainAttributeChanged($event, 'priority')"
        />
      </div>
    </transition>
    <transition name="slide-fade">
      <div
        v-if="newIssue.requiredFields.length > 0"
        :class="{
          'vue-modal__form-step': true,
          'vue-modal__form-step--active':
            newIssue.requiredFields.length > 0 && !showThird
        }"
      >
        <Attribute
          v-for="attribute in newIssue.requiredFields"
          :id="newIssue.project.id"
          :key="attribute.name"
          :bem="bem"
          :data="attribute.data"
          :error-messages="attribute.data.errors"
          :error-type="attribute.data.errorType"
          :required="true"
          @child-value-change="genericAttributeChanged($event, attribute.name)"
        />
      </div>
    </transition>
    <transition name="slide-fade">
      <div
        v-if="newIssue.requiredCustomFields.length > 0"
        :class="{
          'vue-modal__form-step': true,
          'vue-modal__form-step--active': showThird
        }"
      >
        <GenericCf
          v-for="cf in newIssue.requiredCustomFields"
          :id="cf.customField.id"
          :key="cf.customField.id"
          :class="`${block}__custom-field ${block}__attribute`"
          :block="block"
          :bem="bem"
          :no-save="true"
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
          :text-formatting="cf.customField.formatStore.text_formatting"
          :textile="false"
          :with-loading="false"
          :error-messages="cf.errors"
          :error-type="cf.errorType"
          @cf-change="ckChange($event, cf)"
        />
      </div>
    </transition>
    <transition name="slide-fade">
      <EditorBox
        v-if="showCkeditor"
        :config="commentEditConfig"
        :value="newIssue.description"
        :lazy="true"
        :translations="translations"
        :bem="bem"
        :wip-notify="false"
        @valueChanged="descriptionChanged($event)"
      />
    </transition>
    <Notification
      v-show="showErrors"
      :bem="bem"
      type="error"
      class="vue-modal__notification--beforeSubmit"
    >
      <ul style="list-style: none;">
        <li v-for="(error, i) in newIssue.errorsList" :key="i">
          {{ error }}
        </li>
      </ul>
    </Notification>
  </div>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import newIssueValidate from "../../graphql/mutations/newIssueValidate.js";
import apollo from "../../apolloClient";
import GenericCf from "../generalComponents/customFields/GenericCf";
import EditorBox from "../generalComponents/EditorBox";
import Notification from "../generalComponents/Notification";

export default {
  name: "FirstStep",
  components: { Attribute, GenericCf, EditorBox, Notification },
  props: {
    options: Object,
    block: String,
    id: [Number, String],
    bem: Object,
    showErrors: {
      type: Boolean,
      default: false
    },
    newIssue: {
      type: Object,
      default() {
        return {};
      }
    },
    actionButtons: {
      type: Array,
      default() {
        return [];
      }
    }
  },
  data() {
    return {
      authorId: EASY.currentUser.id,
      commentEditConfig: {
        placeholder: "Write your comment",
        edit: false,
        editId: "",
        clearOnSave: false,
        showButtons: false,
        id: "commentEdit",
        startupFocus: false,
      },
      editCommentInput: "",
      showTrackerAttribute: true,
      showSecondAttribute: true,
      ckEditorShown: false,
      translations: this.$store.state.allLocales
    };
  },
  computed: {
    authorInput() {
      return {
        labelName: this.$store.state.allLocales.field_author,
        value: "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        id: "#author-input-select",
        inputType: "autocomplete",
        optionsArray: false,
        filterable: false,
        searchQuery: this.fetchAssignees,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    assigneeInput() {
      return {
        labelName: this.$store.state.allLocales.field_assigned_to,
        value: "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        filterable: false,
        searchQuery: this.fetchAssignees,
        placeholder: "---",
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    dueDateInput() {
      return {
        labelName: this.$store.state.allLocales.field_due_date,
        placeholder: "---",
        date: "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "date",
        optionsArray: false,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    projectInput() {
      return {
        labelName: this.$store.state.allLocales.field_project,
        value: this.$props.newIssue.project.name,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        optionsArray: false,
        inputType: "autocomplete",
        filterable: false,
        searchQuery: this.fetchProject,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    estimatedHoursInput: {
      get() {
        return {
          labelName: this.$store.state.allLocales.field_estimated_hours,
          value: null,
          classes: { edit: ["u-editing"], show: ["u-showing"] },
          inputType: "text",
          optionsArray: false,
          withSpan: true,
          unit: "h",
          editable: true,
          errors: "",
          errorType: null,
          withLoading: false
        };
      }
    },
    storyPointsInput: {
      get() {
        return {
          labelName: this.$store.state.allLocales.field_easy_story_points,
          value: null,
          classes: { edit: ["u-editing"], show: ["u-showing"] },
          inputType: "text",
          optionsArray: false,
          min: 0,
          withSpan: true,
          editable: true,
          errors: "",
          errorType: null,
          withLoading: false
        };
      }
    },
    milestonesInput() {
      return {
        labelName: "milestone",
        value: "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        fetchItemName: "milestones",
        searchQuery: this.fetchMilestones,
        filterable: true,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    trackerInput() {
      return {
        labelName: this.$store.state.allLocales.field_tracker,
        value: this.$props.newIssue.tracker.name,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        fetchItemName: "trackers",
        searchQuery: this.fetchItem,
        filterable: true,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    sprintsInput() {
      return {
        labelName: this.$store.state.allLocales.label_agile_sprint,
        value: "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        fetchItemName: "sprints",
        searchQuery: this.fetchSprint,
        filterable: true,
        firstOptionEmpty: true,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    statusInput() {
      return {
        labelName: this.$store.state.allLocales.field_status,
        value: this.$props.newIssue.status.name,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        fetchItemName: "statuses",
        searchQuery: this.fetchItem,
        filterable: true,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    priorityInput() {
      return {
        labelName: this.$store.state.allLocales.field_priority,
        value: this.$props.newIssue.priority.name,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        fetchItemName: "priorities",
        filterable: true,
        searchQuery: this.fetchItem,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    startDateInput() {
      return {
        labelName: this.$store.state.allLocales.field_start_date,
        placeholder: "---",
        date: null,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "date",
        optionsArray: false,
        withSpan: false,
        editable: true,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    subjectInput() {
      return {
        labelName: "subject",
        classes: {
          edit: ["u-editing"],
          show: ["u-showing editable-input__wrapper--subject"]
        },
        placeholder: "",
        value: this.$props.newIssue.subject,
        inputType: "text",
        withSpan: false,
        editable: true,
        optionsArray: false,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    showProject() {
      return this.$props.newIssue.subject !== "" || this.firstRequiredData;
    },
    showTracker() {
      return (
        this.$props.newIssue.project.id !== null && this.showTrackerAttribute
      );
    },
    showCkeditor(){
      let show = this.$props.newIssue.project.id !== null &&
        this.$props.newIssue.tracker.id !== null;

      if (show && !this.ckEditorShown){
        this.setCkeditorShow();
      }
      if (this.ckEditorShown){
        show = true;
      }
      return show;
    },
    showSecond() {
      return (
        this.$props.newIssue.project.id !== null &&
        this.$props.newIssue.tracker.id !== null &&
        this.showSecondAttribute &&
        this.showTrackerAttribute
      );
    },
    showThird() {
      let filled = true;
      if (
        this.$props.newIssue.requiredCustomFields.length > 0 &&
        this.$props.newIssue.requiredFields.length > 0
      ) {
        this.$props.newIssue.requiredFields.forEach(attribute => {
          if (!attribute.filled) filled = false;
        });
      }
      return filled;
    },
    firstRequiredData() {
      if (this.newIssue.project.id === null) return false;
      return true;
    }
  },
  mounted() {
    this.$refs.subjectInput.focusAttribute();
  },
  methods: {
    assignRequiredFields(data) {
      const requiredAttributeNames = data.requiredAttributeNames;
      const requiredFields = [];
      const requiredCustomFields = [];
      const regex = new RegExp("^[0-9]*$");
      requiredAttributeNames.forEach(name => {
        if (regex.test(name)) {
          const customField = data.customValues.find(
            val => val.customField.id === name
          );
          if (!customField) return;
          customField.errors = [];
          customField.errorType = null;
          requiredCustomFields.push(customField);
          return;
        }
        switch (name) {
          case "assigned_to_id":
            requiredFields.push({
              name: name,
              data: this.assigneeInput,
              filled: !!this.assigneeInput.value
            });
            break;
          case "fixed_version_id":
            requiredFields.push({
              name: name,
              data: this.milestonesInput,
              filled: !!this.milestonesInput.value
            });
            break;
          case "start_date":
            requiredFields.push({
              name: name,
              data: this.startDateInput,
              filled: !!this.startDateInput.value
            });
            break;
          case "due_date":
            requiredFields.push({
              name: name,
              data: this.dueDateInput,
              filled: !!this.dueDateInput.value
            });
            break;
          case "estimated_hours":
            requiredFields.push({
              name: name,
              data: this.estimatedHoursInput,
              filled: !!this.estimatedHoursInput.value
            });
            break;
        }
      });
      const payload = {
        name: "requiredFields",
        value: requiredFields
      };
      this.$store.dispatch("newIssueValidate", payload);
      const customFieldPayload = {
        name: "requiredCustomFields",
        value: requiredCustomFields
      };
      this.$store.dispatch("newIssueValidate", customFieldPayload);
    },
    async compareMainData(data) {
      if (
        !!data.tracker &&
        (+data.tracker.id !== this.$props.newIssue.tracker.id)
      ) {
        this.$props.newIssue.tracker.id = +data.tracker.id;
        this.$props.newIssue.tracker.name = data.tracker.name;
        this.showTrackerAttribute = false;
        await this.$nextTick();
        this.showTrackerAttribute = true;
      }
      if (
        !!data.status &&
        (+data.status.id !== this.$props.newIssue.status.id)
      ) {
        this.$props.newIssue.status.id = +data.status.id;
        this.$props.newIssue.status.name = data.status.name;
        this.showSecondAttribute = false;
        await this.$nextTick();
        this.showSecondAttribute = true;
      }
      if (
        !!data.priority &&
        (+data.priority.id !== this.$props.newIssue.priority.id)
      ) {
        this.$props.newIssue.priority.id = +data.priority.id;
        this.$props.newIssue.priority.name = data.priority.name;
        this.showSecondAttribute = false;
        await this.$nextTick();
        this.showSecondAttribute = true;
      }
    },
    ckChange(value, customField) {
      customField.value = value;
      this.newIssueValidation();
    },
    setCkeditorShow () {
  this.ckEditorShown = true;
    },
    descriptionChanged(event) {
      const payload = {
        name: "description",
        value: event
      };
      this.$store.dispatch("newIssueValidate", payload);
      this.newIssueValidation();
    },
    async fetchAssignees(id, term) {
      const searchTerm = term || "";
      let assignees = [];
      const response = await fetch(
        `/easy_autocompletes/assignable_principals_issue?project_id=${this.newIssue.project.id}&term=${searchTerm}`
      );
      let json = await response.json();
      const users = json.users;
      users.forEach(element => {
        const assignee = {
          value: element.value,
          id: element.id
        };
        assignees.push(assignee);
      });
      return assignees;
    },
    async fetchProject(id, search) {
      let request;
      if (!search) {
        request = await new Request(
          `/easy_autocompletes/add_issue_projects?term=`
        );
      } else {
        request = await new Request(
          `/easy_autocompletes/add_issue_projects?term=${search}`
        );
      }
      const response = await fetch(request);
      const data = await response.json();
      return data.projects;
    },
    async fetchMilestones() {
      const request = new Request(
        `/versions.json?project_id=${this.newIssue.project.id}`
      );
      const response = await fetch(request);
      const data = await response.json();
      const milestones = data.entities;
      let milestoneData = [];
      milestones.forEach(obj => {
        milestoneData.push({ id: obj.id || "", value: obj.name || "" });
      });
      return milestoneData;
    },
    async fetchItem(id, search, name) {
      let request;
      let transformedObj = [];
      switch (name) {
        case "priorities":
          request = new Request("/easy_autocompletes/issue_priorities?");
          break;
        case "statuses":
          request = new Request(
            `/easy_autocompletes/allowed_issue_statuses?project_id=${this.newIssue.project.id}`
          );
          break;
        case "sprints":
          request = new Request(
            `/easy_autocompletes/all_sprint_array?project_id=${this.newIssue.project.id}`
          );
          break;
        case "trackers":
          request = new Request(
            `/easy_autocompletes/allowed_issue_trackers?project_id=${id}`
          );
          break;
        case "category":
          request = new Request(
            `/easy_autocompletes/issue_categories.json?project_id=${this.newIssue.project.id}`
          );
      }
      const response = await fetch(request);
      let data = await response.json();
      data.forEach(obj => {
        transformedObj.push({ id: obj.value || "", value: obj.text || "" });
      });
      return transformedObj;
    },
    genericAttributeChanged(event, type) {
      const attribute = this.$props.newIssue.requiredFields.find(
        val => val.name === type
      );
      if (typeof event.inputValue !== "object") {
        attribute.data.value = event.inputValue;
        if (attribute.data.hasOwnProperty("date")) {
          attribute.data.date = event.inputValue;
        }
      } else {
        if (event.inputValue.hasOwnProperty("value")) {
          attribute.data.value = event.inputValue.value;
        }
        if (event.inputValue.hasOwnProperty("id")) {
          attribute.data.id = event.inputValue.id;
        }
      }
      this.newIssueValidation();
    },
    getAttributes() {
      const attributes = {
        project_id: this.$props.newIssue.project.id,
        tracker_id: this.$props.newIssue.tracker.id,
        status_id: this.$props.newIssue.status.id,
        priority_id: this.$props.newIssue.priority.id,
        author_id: this.authorId,
        subject: this.$props.newIssue.subject,
        description: this.$props.newIssue.description,
        custom_field_values: {}
      };
      if (this.$props.newIssue.requiredCustomFields.length > 0) {
        this.$props.newIssue.requiredCustomFields.forEach(val => {
          if (val.value) {
            attributes.custom_field_values[val.customField.id] = val.value;
          }
        });
      }
      if (this.$props.newIssue.requiredFields.length > 0) {
        this.$props.newIssue.requiredFields.forEach(val => {
          if (val.data.hasOwnProperty("id")) {
            attributes[val.name] = val.data.id;
          } else if (val.data.hasOwnProperty("value") && val.data.value) {
            attributes[val.name] = val.data.value;
          }
        });
      }
      if (!attributes.hasOwnProperty("start_date")) {
        attributes["start_date"] = moment(new Date()).format("YYYY-MM-DD");
      }
      return attributes;
    },
    mainAttributeChanged(event, type) {
      const payload = {
        name: type,
        id: event.inputValue.id,
        value: event.inputValue.value
      };
      this.$store.dispatch("newIssueValidate", payload);
      if (this.firstRequiredData) {
        this.newIssueValidation();
      }
    },
    async newIssueValidation() {
      const attributes = this.getAttributes();
      const plugins = this.$store.state.pluginsList;
      const variables = {
        attributes
      };
      const response = await apollo.mutate({
        mutation: newIssueValidate(plugins.easySprint, plugins.checklists),
        variables
      });
      const issue = response.data.issueValidator.issue;
      this.compareMainData(issue);
      this.assignRequiredFields(issue);
      this.clearErrors();
      const errorsList = [];
      const regex = new RegExp("^cf");
      if (response.data.issueValidator.errors.length !== 0) {
        response.data.issueValidator.errors.forEach(val => {
          let customField;
          let attribute;
          if (regex.test(val.attribute)) {
            customField = this.$store.state.newIssue.requiredCustomFields.find(
              el => el.customField.id === val.attribute.match(/\d/g).join("")
            );
          }
          if (!customField) {
            attribute = this.$store.state.newIssue.requiredFields.find(
              el => el.name === val.attribute
            );
          }
          if (!!attribute && attribute.hasOwnProperty("data")) {
            attribute.data.errors = val.fullMessages;
            attribute.data.errorType = "error";
          }
          if (customField) {
            customField.errors = val.fullMessages;
            customField.errorType = "error";
          }
          val.fullMessages.forEach(mess => {
            errorsList.push(mess);
          });
        });
      }
      const payload = {
        name: "errorsList",
        value: errorsList
      };
      await this.$store.dispatch("newIssueValidate", payload);
    },
    subjectChanged(event) {
      const payload = {
        name: "subject",
        value: event.inputValue
      };
      this.$store.dispatch("newIssueValidate", payload);
      if (this.firstRequiredData) {
        this.newIssueValidation();
      }
    },
    clearErrors() {
      this.$store.state.newIssue.requiredFields.forEach(attribute => {
        attribute.data.errors = [];
        attribute.data.errorType = null;
      });
    }
  }
};
</script>

<style scoped></style>
