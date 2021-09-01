<template>
  <div :class="bem.ify(block, element)">
    <p :class="`${bem.ify(block, `${element}-text`)} popup-heading`">
      {{ translations.label_confirmation }}
    </p>
    <p :class="`${bem.ify(block, `${element}-text`)}`">
      {{ spentHours }} {{ questingTranslation }}
    </p>
    <div>
      <fieldset id="button-group">
        <label v-for="(choice, i) in choices" :key="i" :for="choice.id">
          {{ choice.text }}
          <input :id="choice.id" :name="choice.name" type="radio" @input="selectChoice(choice)" />
        </label>
      </fieldset>
    </div>
    <div v-if="showButtons">
      <button
        :class="
          `${bem.ify(
            block,
            `${element}-button-confirm`
          )} button-mini-positive excluded`
        "
        :disabled="!selectedChoice"
        @click.prevent="confirm"
      >
        {{ translations.button_confirm }}
      </button>
      <button
        :class="
          `${bem.ify(block, `${element}-button-cancel`)} button-mini excluded`
        "
        @click.prevent="$emit('confirmed', false)"
      >
        {{ translations.button_cancel }}
      </button>
    </div>
    <div v-else :class="bem.ify(block, `${element}-filter-wrapper`)">
      <div :class="bem.ify(block, `${element}-filter`)">
        <input
          ref="filterInput"
          v-model="filterValue"
          type="text"
          :class="bem.ify(block, `${element}-input`)"
          @input="filterTasks"
        />
      </div>
    </div>
    <TaskList
      v-if="tasklist.length"
      :bem="bem"
      :data="tasksData"
      :in-pop-up="true"
      @item-checked="checkAction($event)"
    />
  </div>
</template>

<script>
import TaskList from "../generalComponents/TaskList";
import allIssuesQuery from "../../graphql/allIssues";

export default {
  name: "ReallocateSpentTime",
  components: {
    TaskList
  },
  props: {
    bem: Object,
    translations: Object,
    confirmText: String,
  },
  data() {
    return {
      text: this.$props.confirmText,
      tasklist: [],
      selectedChoice: null,
      showButtons: true,
      filterValue: "",
      choices: [
        { text: this.translations.text_destroy_time_entries, name: "button-group", id: "destroy" },
        { text: this.translations.text_assign_time_entries_to_project, name: "button-group", id: "nullify" },
        { text: this.translations.text_reassign_time_entries, name: "button-group", id: "reassign" },
      ],
      tasksData: {
        showRowInput: true,
        rowInputType: "radio",
        list: []
      },
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase(),
    };
  },
  computed: {
    questingTranslation() {
      const question = this.translations.text_destroy_time_entries_question;
      const newTranslation = question.substr(8);
      return newTranslation;
    },
    spentHours() {
      const issue = this.$store.state.issue;
      const timeEntries = issue.timeEntries;
      const issueTimeEntries = timeEntries.reduce((sumHours, { hours }) => sumHours + hours, 0);
      let subTasksTimeEntries = 0;
      const subtasks = issue.descendants;
      if (subtasks) {
        const isSubTasksTimeEntries = !!subtasks.find(({ timeEntries }) => timeEntries.length > 0);
        if (isSubTasksTimeEntries) {
          subTasksTimeEntries = subtasks.reduce((sumHours, { timeEntries }) => {
            const hours = timeEntries.reduce((sumHours, { hours }) => sumHours + hours, 0);
            return sumHours + hours;
          }, 0);
        }
      }
      return issueTimeEntries + subTasksTimeEntries;
    }
  },
  methods: {
    checkAction(event) {
      const { item } = event;
      this.selectedIssue = item.id;
      this.confirm();
    },
    async selectChoice(choice) {
      const term = this.filterValue;
      if (choice.id === "reassign") {
        this.tasklist = await this.fetchTaskListData(term);
        this.$set(this.tasksData, "list", this.tasklist);
        this.showButtons = false;
      } else {
        this.$set(this.tasksData, "list", []);
        this.showButtons = true;
      }
        this.selectedChoice = choice;
    },
    async fetchTaskListData(term = "") {
      const projectId = this.$store.state.issue.projectId;
      const payload = {
        name: "allIssues",
        level: "state",
        apolloQuery: {
          query: allIssuesQuery,
          variables: {
            filter: {
              projectId: {
                eq: projectId
              },
              subject: {
                match: term
              }
            }
          }
        }
      };
      const response = await this.$store.dispatch("fetchStateValue", payload);
      return response.data.allIssues;
    },
    async filterTasks() {
      await this.selectChoice(this.selectedChoice);
    },
    async confirm() {
      try {
        const issueId = this.$store.state.issue.id;
        let url = `${window.urlPrefix}/issues/${issueId}.json?todo=${this.selectedChoice.id}`;
        if (this.selectedChoice.id === "reassign") {
          url = `${url}&reassign_to_id=${this.selectedIssue}`;
        }
        const req = new Request(url);
        await fetch(req, { method: "DELETE" });
      } catch (err) {
        this.$store.commit("setNotification", err);
      }
      this.$emit("confirmed", true);
    }
  },
};
</script>

<style lang="scss" scoped></style>
