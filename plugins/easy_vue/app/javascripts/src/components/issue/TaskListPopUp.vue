<template>
  <div :class="bem.ify(block, element)">
    <h4 :class="bem.ify(bem.block, `${element}-heading`) + ' popup-heading'">
      {{ settings.heading }}
    </h4>
    <div :class="bem.ify(block, `${element}-filter-wrapper`)">
      <div :class="bem.ify(block, `${element}-filter`)">
        <input
          ref="filterInput"
          v-model="filterValue"
          type="text"
          :class="bem.ify(block, `${element}-input`)"
          @input="filterPersons"
        />
        <button
          v-if="settings.multiselect"
          :class="buttonSaveClass"
          :disabled="buttonDisabled"
          @click="save()"
        >
          {{ translations.button_create }}
        </button>
      </div>
      <div
        v-if="settings.multiselect"
        :class="bem.ify(block, `${element}-relations`)"
      >
        <label>
          {{ translations.label_issue_new_relation_before }}
        </label>
        <select
          v-if="settings.multiselect"
          v-model="relationType"
          type="select"
          :class="bem.ify(block, `${element}-input-relations`)"
        >
          <option
            v-for="(relation, i) in settings.selectOptionsArray"
            :key="i"
            :value="relation.key"
          >
            {{ relation.name }}
          </option>
        </select>
      </div>
      <div v-if="showDelay" :class="bem.ify(block, `${element}-delay`)">
        <label> {{ translations.field_delay }} : </label>
        <input v-model="delay" type="text" />
      </div>
      <ul
        v-show="settings.multiselect && itemList.length"
        :class="bem.ify(block, `${element}-list`)"
      >
        <li
          v-for="(item, i) in itemList"
          :key="i"
          :class="bem.ify(block, `${element}-list-item`)"
        >
          {{ item.subject }}
          <a
            title="Delete"
            class="icon icon-delete excluded"
            @click.prevent="deleteItem(item, i)"
          />
        </li>
      </ul>
    </div>
    <slot name="buttons" />
    <TaskList
      v-if="tasklist.length"
      :bem="bem"
      :data="tasksData"
      :in-pop-up="inPopUp"
      @item-checked="checkAction($event, settings.action)"
    />
  </div>
</template>

<script>
import TaskList from "../generalComponents/TaskList";
import taskListItemQuery from "../../graphql/taskListItemQuery";
import taskListQuery from "../../graphql/taskListQuery";

export default {
  name: "TaskListPopUp",
  components: {
    TaskList
  },
  props: {
    bem: Object,
    options: Object,
    translations: Object,
    inPopUp: Boolean
  },
  data() {
    return {
      relationType: "",
      itemList: [],
      relatedTasksIds: [],
      excludedItems: [],
      delay: 0,
      settings: this.$props.options.data.settings,
      tasklist: this.$props.options.tasks,
      filterValue: "",
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    tasksData() {
      const data = this.$props.options.data.inherited;
      const copyData = { ...data };
      copyData.rowInputType = "checkbox";
      if (!this.settings.multiselect) {
        copyData.rowInputType = "radio";
      }
      this.tasklist.forEach((task, i) => {
        this.$set(this.tasklist[i], "checked", false);
      });
      copyData.showRowInput = this.$props.inPopUp;
      copyData.list = this.tasklist;
      return copyData;
    },
    buttonSaveClass() {
      return {
        button: !this.relationType || !this.itemList.length,
        "button-positive": this.relationType && this.itemList.length
      };
    },
    buttonDisabled() {
      return !(this.relationType && this.itemList.length);
    },
    showDelay() {
      return (
        this.relationType === "precedes" || this.relationType === "follows"
      );
    }
  },
  mounted() {
    if (this.options.data.settings.issuePropName === "relations") {
      this.setDefaultRelation();
    }
    this.$refs.filterInput.focus();
  },
  methods: {
    async filterPersons() {
      const payload = {
        name: this.settings.queryName,
        apolloQuery: {
          query: taskListItemQuery(
            this.settings.queryName,
            `"${this.filterValue}"`
          ),
          variables: { id: this.$store.state.issue.id }
        }
      };
      await this.$store.dispatch("fetchIssueValue", payload);
      this.tasklist = this.$store.state.issue[this.settings.queryName];
    },
    async checkAction(eventData, action) {
      const { item: task, i } = eventData;
      await this[action](task, i);
    },
    async reFetchValue() {
      const fetchItemsPayload = {
        name: this.settings.issuePropName,
        apolloQuery: {
          query: taskListQuery(this.settings.issuePropName),
          variables: { id: this.$store.state.issue.id }
        }
      };
      await this.$store.dispatch("fetchIssueValue", fetchItemsPayload);
    },
    async addParent(task) {
      const saveItemPayload = {
        reqBody: {
          name: this.settings.issuePropName,
          value: { task },
          issue: {
            parent_issue_id: task.id
          },
          localId: this.$store.state.issue.id
        }
      };
      await this.$store.dispatch("saveIssueStateValue", saveItemPayload);
      await this.reFetchValue();
      this.$emit("onBlur");
    },
    async addRelation(task, i) {
      const exist = this.itemList.find(item => item.id === task.id);
      if (!exist) {
        this.relatedTasksIds.push(task.id);
        this.itemList.push(task);
      } else if (exist && i) {
        this.$delete(this.itemList, i);
        this.$delete(this.relatedTasksIds, i);
      } else {
        this.itemList.forEach((el, i) => {
          if (el.id === task.id) {
            this.$delete(this.itemList, i);
            this.$delete(this.relatedTasksIds, i);
          }
        });
      }
    },
    deleteItem(item, i) {
      this.tasklist.forEach((task, i) => {
        if (task.id === item.id) {
          this.$set(this.tasklist[i], "checked", false);
        }
      });
      this.$delete(this.itemList, i);
      this.$delete(this.relatedTasksIds, i);
    },
    async save() {
      const issueId = this.$store.state.issue.id;
      const payload = {
        reqBody: {
          relation: {
            relation_type: this.relationType,
            issue_to_id: this.relatedTasksIds,
            delay: this.delay || ""
          },
          issue_id: issueId
        },
        url: `${window.urlPrefix}/issues/${issueId}/relations.json`,
        reqType: "post"
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      await this.reFetchValue();
      this.$emit("onBlur");
    },
    setDefaultRelation() {
      const relationArray = this.$props.options.data.settings
        .selectOptionsArray;
      if (relationArray && relationArray.length) {
        this.relationType = relationArray[0].key;
      }
    }
  }
};
</script>
