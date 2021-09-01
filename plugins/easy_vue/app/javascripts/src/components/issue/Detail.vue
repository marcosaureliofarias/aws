<template>
  <section id="detail" :class="bem.ify(block, 'section')">
    <ul v-if="showAttrs" :class="bem.ify(block, 'attributes')">
      <Attribute
        :id="task.id"
        ref="status"
        :bem="bem"
        :data="statusInput"
        @child-value-change="makeWorkflow($event, 'status_id', 'status')"
      />
      <Attribute
        v-if="showByTracker('priority_id')"
        :id="task.id"
        :bem="bem"
        :data="priorityInput"
        @child-value-change="
          saveValue($event, 'priority_id', 'priority', getPriority)
        "
      />
      <Attribute
        v-if="showByTracker('assigned_to_id')"
        :id="task.id"
        ref="assignee"
        :bem="bem"
        :data="assigneeInput"
        @child-value-change="saveValue($event, 'assigned_to_id', 'assignedTo')"
      />
      <Attribute
        v-if="showByTracker('author_id')"
        :id="task.id"
        :bem="bem"
        :data="authorInput"
        @child-value-change="saveValue($event, 'author_id', 'author')"
      />
      <Attribute
        v-if="showByTracker('start_date')"
        :id="task.id"
        :bem="bem"
        :data="startDateInput"
        @child-value-change="
          changeIssueRange($event, 'start_date', 'startDate', getValue)
        "
      />
      <Attribute
        v-if="showByTracker('due_date')"
        :id="task.id"
        :bem="bem"
        :data="dueDateInput"
        @child-value-change="
          changeIssueRange($event, 'due_date', 'dueDate', getValue)
        "
      />
      <Attribute :id="task.id" :bem="bem" :data="createdInput" />
      <PopUpAttribute
        v-if="
          isFeatureEnabled('issue_duration') && showByTracker('easy_duration')
        "
        :id="task.id"
        :bem="bem"
        :data="durationInput"
        @open-popup="emitPopUpOpen"
      />
      <Attribute
        v-if="
          isModuleEnabled('time_tracking') && showByTracker('estimated_hours')
        "
        :id="task.id"
        :bem="bem"
        :data="estimatedHoursInput"
        @child-value-change="
          saveValue($event, 'estimated_hours', 'estimatedHours', getValue)
        "
      />
      <Attribute
        v-if="isModuleEnabled('time_tracking') && spentHoursEditable"
        :id="task.id"
        :bem="bem"
        :data="spentHoursInput"
      />
      <Attribute
        v-if="showByTracker('tracker_id')"
        :id="task.id"
        :bem="bem"
        :data="trackerInput"
        @child-value-change="makeWorkflow($event, 'tracker_id')"
      />
      <Attribute
        v-if="showByTracker('fixed_version_id')"
        :id="task.id"
        :bem="bem"
        :data="milestonesInput"
        @child-value-change="saveValue($event, 'fixed_version_id', 'version')"
      />
      <Attribute
        v-if="scrumVisible()"
        :id="task.id"
        :bem="bem"
        :data="sprintsInput"
        @child-value-change="saveValue($event, 'easy_sprint_id', 'easySprint')"
      />
      <Attribute
        v-if="scrumVisible()"
        :id="task.id"
        :bem="bem"
        :data="storyPointsInput"
        @child-value-change="
          saveValue($event, 'easy_story_points', 'easyStoryPoints', getValue)
        "
      />
      <Attribute
        v-if="showByTracker('project_id')"
        :id="task.id"
        :bem="bem"
        :data="projectInput"
      />
      <Attribute
        v-if="showByTracker('category_id')"
        :id="task.id"
        :bem="bem"
        :data="categoryInput"
        @child-value-change="
          setCategoryChanges($event, 'category_id', 'category')
        "
      />
    </ul>
    <ul v-else :class="bem.ify(block, 'attributes')">
      <li v-for="i in 12" :key="i" :class="`${block}__attribute--fake`">
        <div :class="`gradient label`" />
        <div :class="`gradient u-showing editable-input__wrapper--fake`" />
      </li>
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import PopUpAttribute from "../generalComponents/PopUpAttribute";
import issueHelper from "../../store/actionHelpers";
import issuePrimaryQueryBuilder from "../../graphql/issue";

export default {
  name: "Detail",
  components: {
    Attribute,
    PopUpAttribute
  },
  props: {
    task: {
      type: Object,
      default: () => {}
    },
    bem: {
      type: Object,
      default: () => "vue_modal"
    },
    spentHours: {
      type: Number,
      default: () => 0
    },
    additionalRights: {
      type: Object,
      default: () => {
        return { project: true };
      }
    }
  },
  data() {
    return {
      showAttrs: true,
      statuses: [],
      assignees: [],
      createdDate: this.dateFormat(this.$props.task.createdOn),
      priorities: [],
      sprints: [],
      milestones: [],
      componentOrder: [],
      durationUnit: this.$store.state.allLocales.label_day_plural,
      getPriority: issueHelper.getPriority,
      spentHoursEditable: this.$props.spentHours !== null,
      block: this.$props.bem.block,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase()
    };
  },
  computed: {
    deletableRights() {
      const additRights = this.$props.additionalRights;
      if (additRights && additRights.deletable) {
        return additRights.deletable;
      }
      return {};
    },
    authorInput() {
      return {
        labelName: this.$store.state.allLocales.field_author,
        value: this.$props.task ? this.$props.task.author : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        id: "#author-input-select",
        inputType: "autocomplete",
        attribute: "author_id",
        optionsArray: false,
        filterable: false,
        searchQuery: this.fetchAssignees,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("author_id")
      };
    },
    projectInput() {
      return {
        labelName: this.$store.state.allLocales.field_project,
        value: this.$props.task.project ? this.$props.task.project : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        optionsArray: false,
        inputType: "autocomplete",
        attribute: "project_id",
        filterable: false,
        withSpan: false,
        editable: false
      };
    },
    assigneeInput() {
      return {
        labelName: this.$store.state.allLocales.field_assigned_to,
        value: this.$props.task.assignedTo ? this.$props.task.assignedTo : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "assigned_to_id",
        optionsArray: false,
        filterable: false,
        searchQuery: this.fetchAssignees,
        placeholder: "---",
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("assigned_to_id")
      };
    },
    priorityInput() {
      return {
        labelName: this.$store.state.allLocales.field_priority,
        value: this.$props.task.priority ? this.$props.task.priority : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "priority_id",
        optionsArray: false,
        fetchItemName: "priorities",
        filterable: true,
        searchQuery: this.fetchItem,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("priority_id")
      };
    },
    startDateInput() {
      return {
        labelName: this.$store.state.allLocales.field_start_date,
        placeholder: "---",
        date: this.$props.task.startDate,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "date",
        attribute: "start_date",
        optionsArray: false,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("start_date"),
        cleareable: this.deletableRights.start_date
      };
    },
    dueDateInput() {
      return {
        labelName: this.$store.state.allLocales.field_due_date,
        placeholder: "---",
        date: this.$props.task.dueDate,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "date",
        attribute: "due_date",
        optionsArray: false,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("due_date"),
        cleareable: this.deletableRights.due_date
      };
    },
    statusInput() {
      return {
        labelName: this.$store.state.allLocales.field_status,
        value: this.$props.task.status ? this.$props.task.status.name || this.$props.task.status.value : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "status_id",
        optionsArray: false,
        fetchItemName: "statuses",
        searchQuery: this.fetchItem,
        filterable: true,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("status_id")
      };
    },
    trackerInput() {
      return {
        labelName: this.$store.state.allLocales.field_tracker,
        value: this.$props.task.tracker ? this.$props.task.tracker.name : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "tracker_id",
        optionsArray: false,
        fetchItemName: "trackers",
        searchQuery: this.fetchItem,
        filterable: true,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("tracker_id")
      };
    },
    sprintsInput() {
      return {
        labelName: this.$store.state.allLocales.label_agile_sprint,
        value: this.$props.task.easySprint
          ? this.$props.task.easySprint.name || this.$props.task.easySprint.value
          : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "easy_sprint_id",
        optionsArray: false,
        fetchItemName: "sprints",
        searchQuery: this.fetchSprint,
        filterable: true,
        firstOptionEmpty: true,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("easy_sprint_id")
      };
    },
    milestonesInput() {
      const issue = this.$store.state.issue;
      let value = "";
      if (issue && issue.version) {
        value = issue.version.name || issue.version.value;
      }
      return {
        labelName: this.$store.state.allLocales.label_fixed_version,
        value,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "fixed_version_id",
        optionsArray: false,
        fetchItemName: "milestones",
        searchQuery: this.fetchItem,
        filterable: true,
        withSpan: false,
        editable:
          this.task.editable && this.workFlowChangable("fixed_version_id")
      };
    },
    createdInput() {
      return {
        labelName: this.$store.state.allLocales.field_created_on,
        value: this.dateFormat(this.$props.task.createdOn),
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "select",
        attribute: "created_at",
        optionsArray: [],
        withSpan: false,
        editable: this.task.editable
      };
    },
    spentHoursInput() {
      return {
        labelName: this.$store.state.allLocales.label_spent_time,
        value: this.$props.spentHours.toFixed(2) + " h",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "text",
        attribute: "spent_hours",
        optionsArray: [],
        withSpan: false,
        editable: this.task.editable,
        req: false
      };
    },
    categoryInput() {
      return {
        labelName: this.$store.state.allLocales.field_category,
        value: this.$props.task.category,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "category_id",
        optionsArray: false,
        fetchItemName: "category",
        searchQuery: this.fetchItem,
        filterable: true,
        withSpan: false,
        editable: this.task.editable && this.workFlowChangable("category_id")
      };
    },
    estimatedHoursInput: {
      get() {
        return {
          labelName: this.$store.state.allLocales.field_estimated_hours,
          value: this.$props.task.estimatedHours
            ? parseFloat(this.$props.task.estimatedHours).toFixed(2)
            : null,
          classes: { edit: ["u-editing"], show: ["u-showing"] },
          inputType: "text",
          attribute: "estimated_hours",
          optionsArray: false,
          withSpan: true,
          unit: "h",
          editable:
            this.task.editable && this.workFlowChangable("estimated_hours")
        };
      }
    },
    durationInput() {
      return {
        labelName: this.$store.state.allLocales.field_easy_duration,
        value: this.$props.task.duration,
        inputType: "text",
        attribute: "easy_duration",
        unit: this.durationUnit,
        component: "Duration",
        editable: this.task.editable && this.workFlowChangable("easy_duration")
      };
    },
    storyPointsInput: {
      get() {
        return {
          labelName: this.$store.state.allLocales.field_easy_story_points,
          value: this.$props.task.easyStoryPoints
            ? this.$props.task.easyStoryPoints
            : null,
          classes: { edit: ["u-editing"], show: ["u-showing"] },
          inputType: "text",
          attribute: "easy_story_points",
          optionsArray: false,
          min: 0,
          withSpan: true,
          editable:
            this.task.editable && this.workFlowChangable("easy_story_points")
        };
      }
    }
  },
  mounted() {
    this.setShortcuts();
  },
  methods: {
    setShortcuts() {
      const storeShortcuts = this.$store.state.shortcuts;
      const shortcuts = [
        {
          key: "a",
          ref: this.$refs.assignee,
          options: {
            focus: true
          }
        },
        {
          key: "s",
          ref: this.$refs.status,
          options: {
            focus: true
          }
        }
      ];

      storeShortcuts.forEach(storeShortcut => {
        const existingKey = shortcuts.some(
          shortcut => shortcut.key === storeShortcut.key
        );
        if (!existingKey) shortcuts.push(storeShortcut);
      });

      const payload = {
        name: "shortcuts",
        value: [],
        level: "state"
      };
      this.$store.commit("setStoreValue", payload);
      shortcuts.forEach(shortcut => this.registerShortcut(shortcut));
    },
    async fetchAssignees(id, term) {
      let assignees = [];
      const searchTerm = term || "";
      const issueID = this.$props.task.id;
      const response = await fetch(
        `${window.urlPrefix}/easy_autocompletes/assignable_principals_issue?issue_id=${issueID}&term=${searchTerm}`
      );
      let json = await response.json();
      const users = json.users;
      users.forEach(element => {
        const { value, id, attendance_status, attendance_status_css } = element;
        const assignee = {
          value,
          id,
          attendance_status,
          attendance_status_css
        };
        assignees.push(assignee);
      });
      const options = {
        value: assignees,
        name: "assignableUsers",
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
      return assignees;
    },
    async fetchItem(id, search, name) {
      let request;
      let transformedObj = [];
      switch (name) {
        case "priorities":
          request = new Request(
            `${window.urlPrefix}/easy_autocompletes/issue_priorities?`
          );
          break;
        case "statuses":
          request = new Request(
            `${window.urlPrefix}/easy_autocompletes/allowed_issue_statuses?issue_id=${id}`
          );
          break;
        case "sprints":
          request = new Request(
            `${window.urlPrefix}/easy_autocompletes/all_sprint_array?issue_id=${id}`
          );
          break;
        case "milestones":
          request = new Request(
            `${window.urlPrefix}/easy_autocompletes/assignable_versions?issue_id=${id}`
          );
          break;
        case "trackers":
          request = new Request(
            `${window.urlPrefix}/easy_autocompletes/allowed_issue_trackers?issue_id=${id}`
          );
          break;
        case "category":
          request = new Request(
            `${window.urlPrefix}/easy_autocompletes/issue_categories.json?project_id=${this.task.project.id}`
          );
      }
      const response = await fetch(request);
      let data = await response.json();
      data.forEach(obj => {
        transformedObj.push({ id: obj.value || "", value: obj.text || "" });
      });
      return transformedObj;
    },
    async fetchSprint(id) {
      let sprints = [];
      const request = new Request(
        `${window.urlPrefix}/easy_autocompletes/all_sprint_array?issue_id=${id}`
      );
      // TODO přepsat
      const response = await fetch(request);
      let data = await response.json();
      if (!data) return;
      data.forEach(project => {
        if (Array.isArray(project)) return;
        project.children.forEach(child => {
          sprints.push({
            id: Object.keys(child)[0],
            value: Object.values(child)[0]
          });
        });
      });
      return sprints;
    },
    async makeWorkflow(payload, propName, graphqlProp) {
      const { saved, toBuffer } = await this.saveValue(
        payload,
        propName,
        graphqlProp
      );
      if (saved && !toBuffer) {
        if (this.timer) clearTimeout(this.timer);
        this.timer = setTimeout(async () => {
          this.showAttrs = !saved;
          await this.getIssue(this.$store);
          this.showAttrs = true;
        }, 1000);
      }
      await this.$nextTick();
      this.setShortcuts();
    },
    async getIssue(store) {
      const plugins = store.state.pluginsList;
      const ryses = store.state.ryses;
      const payload = {
        name: "issue",
        apolloQuery: {
          query: issuePrimaryQueryBuilder(
            plugins.easySprint,
            plugins.checklists,
            ryses.duration
          ),
          variables: {
            id: this.$props.task.id
          }
        },
        commit: "setPropsByName",
        level: "state"
      };
      await store.dispatch("fetchStateValue", payload);
    },
    async setCategoryChanges(payload, propName, graphqlProp) {
      const { saved } = await this.saveValue(payload, propName, graphqlProp);
      if (saved) {
        this.showAttrs = !saved;
        await this.getIssue(this.$store);
        this.showAttrs = true;
      }
    },
    async getValidatedIssue(prop, id) {
      const payload = {
        name: "issue",
        attrs: {
          [prop]: id
        },
        level: "state"
      };
      this.$store.dispatch("validate", payload);
    },
    scrumVisible() {
      const isScrumModule =
        this.isModuleEnabled("easy_kanban_board") ||
        this.isModuleEnabled("easy_scrum_board");
      const showSprint = this.task.easySprintVisible;
      return isScrumModule || showSprint;
    },
    emitPopUpOpen(payload) {
      this.$emit("open-popup", payload);
    },
    changeIssueRange($event, names) {
      const payload = {
        changing: {
          [names]: $event.inputValue
        },
        showFlashMessage: $event.showFlashMessage
      };
      this.$emit("rangeChange", payload);
    }
  }
};
</script>

<style scoped></style>
