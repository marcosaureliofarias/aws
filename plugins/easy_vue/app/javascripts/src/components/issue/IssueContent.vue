<template>
  <div>
    <Overview
      :bem="bem"
      :task="task"
      :spent-hours="spentHours"
      :estimated-hours="task.estimatedHours"
      @list-more="$emit('list-more', $event)"
    />
    <Detail
      :task="task"
      :bem="bem"
      :additional-rights="additionalRights"
      :spent-hours="spentHours"
      @open-popup="showPopUp"
      @rangeChange="changeRange($event)"
    />
    <CustomFields
      v-if="additionalDataFetched && customFields.length"
      :custom-fields="customFields"
      :block="block"
      :bem="bem"
      :translations="translations"
      :task="task"
      :textile="textile"
      @open-required-popup="openRequiredCFsPopup"
    />
    <div
      v-if="!additionalDataFetched || !customFields.length"
      class="custom-fields__button-panel--faked"
    />

    <Description
      v-if="showByTracker('description')"
      :entity="task"
      :bem="bem"
      :editable="task.editable"
      :textile="textile"
      @save="saveDescription"
    />

    <!--wait until data are loaded-->
    <template v-if="additionalDataFetched">
      <Comments
        :journals="task.journals"
        :bem="bem"
        :permissions="commentsPermissions"
        :is-mobile="isMobile"
        :textile="textile"
        @add-comment="addComment"
        @delete-comment="deleteComment"
        @update-comment="updateComment"
        @fetch-all-journals="fetchAllJournals"
        @add-emoji="addEmoji($event)"
        @remove-emoji="removeEmoji($event)"
      />
      <MergeRequests
        v-if="showMergeRequests()"
        :task="task"
        :bem="bem"
        :data="mergeRequestSetting"
      />
      <Attachments
        ref="attachmentsComponent"
        :bem="bem"
        :task="task"
        :options="attachments"
        :custom-values="$store.state.attachmentsCustomValues"
        :is-mobile="isMobile"
      />
      <SpentTimeList
        v-if="activateComponents(translations.label_spent_time)"
        :task="task"
        :bem="bem"
        :block="block"
        :spent-hours="spentHours"
        :textile="textile"
        :is-mobile="isMobile"
      />
      <CheckList
        v-if="
          activateComponents(translations.label_easy_checklist_plural) &&
            task.project.visibleChecklists
        "
        :bem="bem"
        :checklists="checklists"
        @ratioChanged="getListRatio($event)"
      />
      <TaskList
        v-if="task.descendants.length"
        :bem="bem"
        :data="tasksData(subtaskSettings)"
        @removeItem="removeSubtask($event)"
        @openTask="openTaskModal($event)"
      />
      <TaskList
        v-if="task.ancestors.length"
        :bem="bem"
        :data="tasksData(parentSettings)"
        @openTask="openTaskModal($event)"
      />
      <TaskList
        v-if="task.relations.length"
        :bem="bem"
        :data="tasksData(relatedSettings)"
        @removeItem="removeRelatedTask($event)"
        @openTask="openTaskModal($event)"
      />
      <PopUp
        v-if="currentComponent"
        :bem="bem"
        :align="alignment"
        :task="task"
        :component="currentComponent"
        :options="popUpOptions"
        :custom-styles="popUpCustomStyles"
        :translations="$store.state.allLocales"
        :is-mobile="isMobile"
        @onBlur="currentComponent = null"
        @confirmed="confirmAction($event)"
      />
    </template>
    <div v-else :class="bem.ify(block) + '__fake-data'">
      <div :class="`${bem.ify(block)}__fake-data__header gradient`" />
      <div :class="`${bem.ify(block)}__fake-data__body gradient`" />
      <div :class="`${bem.ify(block)}__fake-data__buttons`" />
      <div
        :class="
          `${bem.ify(block)}__fake-data__header ${bem.ify(
            block
          )}__fake-data__header--journal gradient`
        "
      />
      <div
        :class="
          `${bem.ify(block)}__fake-data__body ${bem.ify(
            block
          )}__fake-data__body--journal gradient`
        "
      />
      <div
        :class="
          `${bem.ify(block)}__fake-data__header ${bem.ify(
            block
          )}__fake-data__header--journal gradient`
        "
      />
      <div
        :class="
          `${bem.ify(block)}__fake-data__body ${bem.ify(
            block
          )}__fake-data__body--journal gradient`
        "
      />
    </div>
  </div>
</template>
<script>
import Comments from "./Comments";
import Description from "../generalComponents/Description";
import Detail from "./Detail";
import SpentTimeList from "./SpentTimeList";
import Overview from "./Overview";
import CheckList from "./CheckList";
import TaskList from "../generalComponents/TaskList";
import MergeRequests from "./MergeRequests";
import PopUp from "../generalComponents/PopUp";
import issueAdditionalQueryBuilder from "../../graphql/additionalIssueData";
import {
  allAvailableEmojisQuery,
  createEmoji,
  removeEmoji
} from "../../graphql/emojis.js";
import Vue from "vue";
import attachmentsCFQuery from "../../graphql/attacmentsCustomFields";
import CustomFields from "./CustomFields";
import mutation from "../../graphql/mutations/duration";
import allUsersQuery from "../../graphql/allUsers";

export default {
  name: "IssueContent",
  components: {
    CustomFields,
    Detail,
    Comments,
    Description,
    SpentTimeList,
    Overview,
    CheckList,
    TaskList,
    MergeRequests,
    PopUp
  },
  props: {
    task: Object,
    bem: Object,
    activeBtns: {
      type: Array,
      default() {
        return [];
      }
    },
    isMobile: {
      type: Boolean,
      default: false
    },
    additionalRights: {
      type: Object,
      default: () => {}
    },
    block: {
      type: String,
      default() {
        return "";
      }
    }
  },
  data() {
    return {
      currentComponent: null,
      top: 0,
      popUpOptions: [],
      popUpCustomStyles: {},
      alignment: {},
      parentSettings: {
        name: "parentTasks",
        deleteObj: {
          value: false,
          icon: null
        },
        permissions: {
          delete: this.additionalRights ? this.additionalRights.addParentTasks : true
        }
      },
      subtaskSettings: {
        name: "subtasks",
        deleteObj: {
          value: true,
          icon: "icon icon-del",
          title: this.$store.state.allLocales.title_issue_remove_parent
        },
        permissions: {
          delete: this.additionalRights ? this.additionalRights.addSubTasks : true
        }
      },
      relatedSettings: {
        name: "relatedTasks",
        deleteObj: {
          value: true,
          icon: "icon icon-unlink",
          title: this.$store.state.allLocales.label_relation_delete
        },
        permissions: {
          delete: this.additionalRights ? this.additionalRights.addRelatedTasks : true
        }
      },
      translations: this.$store.state.allLocales,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase()
    };
  },
  computed: {
    attachments() {
      return this.$store.state.issue.attachments;
    },
    additionalDataFetched() {
      return (
        this.$store.state.additionalDataFetched &&
        this.$store.state.issue.journals
      );
    },
    journals() {
      return this.$store.state.issue.journals;
    },
    mergeRequestSetting() {
      const mergeRequestSetting = {
        list: this.$store.state.issue.easyGitIssue.rows,
        anchor: "merge_requests_anchor"
      };
      return mergeRequestSetting;
    },
    customFields() {
      if (!this.$props.task.customValues) return [];
      return this.$props.task.customValues;
    },
    subtasks() {
      this.$emit("taskListChecked", {
        ref: "subtasks",
        value: !!this.$props.task.descendants.length > 0
      });
      return this.$props.task.descendants;
    },
    parentTasks() {
      this.$emit("taskListChecked", {
        ref: "parentTasks",
        value: !!this.$props.task.ancestors.length > 0
      });
      return this.$props.task.ancestors;
    },
    relatedTasks() {
      let relationTasks = [];
      this.$props.task.relations.forEach(task => {
        if (task.otherIssue) {
          const {
            assignedTo,
            doneRatio,
            id,
            status,
            subject,
            priority,
            easyLevel
          } = task.otherIssue;
          task = {
            relationId: task.id,
            relation: task.relationName,
            easyLevel,
            assignedTo,
            doneRatio,
            id,
            status,
            subject,
            priority
          };
        }
        relationTasks.push(task);
      });
      this.$emit("taskListChecked", {
        ref: "relatedTasks",
        value: !!relationTasks.length > 0
      });
      return relationTasks;
    },
    spentHours() {
      const entries = this.$props.task.timeEntries;
      let spentHours = 0;
      if (entries && entries.length) {
        entries.forEach(entry => {
          spentHours += parseFloat(entry.hours);
        });
      }
      if (!this.$store.state.additionalDataFetched) {
        spentHours = this.$props.task.spentHours;
      }
      return spentHours;
    },
    commentsPermissions() {
      return {
        privateComments: this.task.privateNotesEnabled,
        addableNotes: this.task.addableNotes
      };
    },
    checklists() {
      const self = this;
      let checklists = [];
      const easyChecklists = this.$props.task.checklists;
      if (!easyChecklists) return;
      easyChecklists.forEach(list => {
        const easyChecklistsItems = list.easyChecklistItems;
        let checklistItems = [];
        easyChecklistsItems.forEach(item => {
          const checkListItem = {
            title: item.subject,
            isDone: item.done,
            id: item.id,
            canEnable: item.canEnable,
            canDisable: item.canDisable,
            editable: item.editable,
            deletable: item.deletable
          };
          checklistItems.unshift(checkListItem);
        });
        const checklist = {
          title: list.name,
          id: list.id,
          itemName: null,
          items: checklistItems,
          show: true,
          ratio: 0,
          itemFormShow: false,
          deletable: list.deletable,
          editable: list.editable
        };
        self.getListRatio(checklist);
        checklists.unshift(checklist);
      });
      return checklists;
    },
    textile() {
      if (!this.$store.state.allSettings) return false;
      return this.$store.state.allSettings.text_formatting !== "HTML";
    }
  },
  created() {
    if (this.$store.state.pluginsList.easyEmojis) {
      this.fetchEmojiData();
    }
    this.fetchAdditionalData();
  },
  methods: {
    async saveDescription(inputValue) {
      const value = {
        description: inputValue
      };
      const payload = {
        name: "description",
        value,
        reqBody: {
          issue: value
        }
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
    },
    fetchAllJournals() {
      const options = {
        type: "issue",
        variables: {
          id: this.task.id,
          all: true
        }
      };
      this.$store.dispatch("fetchJournals", options);
      this.$store.commit("setStoreValue", {
        level: "state",
        name: "fetchAllJournals",
        value: true
      });
    },
    addComment(data) {
      const { inputValue, isPrivate } = data;
      const payload = {
        reqBody: {
          issue: {
            notes: inputValue,
            private_notes: isPrivate,
            update_repeat_entity_attributes: 1
          }
        }
      };
      this.$store.dispatch("saveIssueStateValue", payload);
    },
    async addEmoji(event) {
      const payload = {
        mutationName: "journalChange",
        fetchJournals: true,
        apolloMutation: {
          mutation: createEmoji,
          variables: {
            entityId: event.commentID,
            emojiId: event.emojiID
          }
        }
      };
      await this.$store.dispatch("mutateValue", payload);
    },
    async removeEmoji(event) {
      const payload = {
        mutationName: "journalChange",
        fetchJournals: true,
        apolloMutation: {
          mutation: removeEmoji,
          variables: {
            entityId: event.commentID,
            emojiId: event.emojiID
          }
        }
      };
      await this.$store.dispatch("mutateValue", payload);
    },
    updateComment(data) {
      const { value, comment } = data;
      const payload = {
        reqBody: {
          journal: {
            notes: value,
            private_notes: comment.privateNotes
          },
          format: "json"
        },
        url: `${window.urlPrefix}/journals/${comment.id}.json`
      };
      this.$store.dispatch("saveIssueStateValue", payload);
    },
    deleteComment(comment) {
      const payload = {
        reqBody: {
          journal: {
            notes: ""
          },
          format: "json"
        },
        url: `${window.urlPrefix}/journals/${comment.id}.json`
      };
      this.$store.dispatch("saveIssueStateValue", payload);
    },
    activateComponents(name) {
      const active = this.$props.activeBtns;
      let show = false;
      active.forEach(el => {
        if (el.name === name) {
          show = el.isModuleActive;
        }
      });
      return show;
    },
    tasksData(settings) {
      const { name, deleteObj, permissions } = settings;
      const data = this.$props.activeBtns.find(el => el.ref === name);
      if (data) {
        Vue.set(data, "list", this[name]);
        data.sectionName = data.name;
        data.editTitle = "Open in new modal";
        data.delete = deleteObj;
        data.permissions = permissions;
        return data;
      } else {
        return {};
      }
    },
    getListRatio(list) {
      if (!list.items.length) return 0;
      const done = list.items.filter(el => el.isDone).length;
      const all = list.items.length;
      list.ratio = Math.round((done / all) * 100);
    },
    async getUsers() {
      const payload = {
        name: "allUsers",
        apolloQuery: {
          query: allUsersQuery
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchAdditionalData() {
      const plugins = this.$store.state.pluginsList;
      await this.fetchAttachmentsCF();
      await this.getUsers();
      await this.getCoworkers(this.$props.task.id);
      const payload = {
        name: "issue",
        apolloQuery: {
          query: issueAdditionalQueryBuilder(
            plugins.checklists,
            plugins.timeEntries,
            plugins.easyGitIssue,
            plugins.easyEmojis
          ),
          variables: {
            id: this.$props.task.id
          }
        },
        commit: "setAdditionalData"
      };
      await this.$store.dispatch("fetchStateValue", payload);
      this.$emit("attach-escape-events");
    },
    async fetchEmojiData() {
      const payload = {
        name: "allAvailableEmojis",
        apolloQuery: {
          query: allAvailableEmojisQuery
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async getCoworkers() {
      const options = {
        value: this.$props.task.watchers,
        name: "coworkers",
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
    },
    async removeSubtask(eventData) {
      const { id, index } = eventData.row;
      const payload = {
        reqBody: {
          issue: {
            parent_issue_id: ""
          }
        },
        localId: id
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      this.$delete(this.subtasks, index);
      this.$emit("taskListChecked", {
        ref: "subtasks",
        value: !!this.subtasks.length > 0
      });
    },
    async removeRelatedTask(eventData) {
      const { element: relatedTask, index } = eventData.row;
      const task = this.$props.task;
      const relatedTasks = this.relatedTasks.slice(0);
      this.$delete(relatedTasks, index);
      const payload = {
        name: "relations",
        value: {
          relations: relatedTasks
        },
        reqBody: {
          data: {
            issue_id: task.id,
            id: relatedTask.relationId
          }
        },
        reqType: "delete",
        url: `${window.urlPrefix}/relations/${relatedTask.relationId}.json`
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      this.$emit("taskListChecked", {
        ref: "relatedTasks",
        value: !!relatedTasks.length > 0
      });
    },
    openTaskModal(data) {
      const id = data.row.id;
      this.$emit("close", { id });
    },
    async fetchAttachmentsCF() {
      const payload = {
        name: "attachmentsCustomValues",
        apolloQuery: {
          query: attachmentsCFQuery
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    showPopUp(payload) {
      const { e, componentName } = payload;
      const options = {
        topOffs: 280,
        rightOffs: 375
      };
      this.popUpCustomStyles = {
        width: "auto",
        height: "160px !important"
      };
      this.popUpOptions = {
        heading: this.translations.field_easy_duration,
        duration: {
          unit: this.task.availableDurationUnits.find(el => el.key === "day"),
          value: this.task.duration
        },
        units: this.task.availableDurationUnits
      };
      this.alignment = this.getAlignment(e, options, this.$props.isMobile);
      this.currentComponent = componentName;
    },
    async confirmAction(payload) {
      await this.changeRange(payload);
    },
    async changeRange(payload) {
      let { changing } = payload;
      const localSave = this.$store.state.localSave;
      const mutationPayload = {
        mutationName: "issueDuration",
        apolloMutation: {
          mutation: mutation,
          variables: {
            attributes: this.$store.state.buffer || {},
            changing,
            id: this.task.id,
            toBeSaved: !localSave
          }
        },
        processFunc: payload.showFlashMessage ? payload.showFlashMessage : null
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateIssueRange(data, localSave);
    },
    updateIssueRange(data, localSave) {
      const { issue, errors } = data.issueDuration;
      if (errors.length) return;
      if (localSave) {
        const attributes = [
          { prop: { name: "start_date", value: issue.startDate } },
          { prop: { name: "due_date", value: issue.dueDate } },
          { prop: { name: "duration", value: issue.duration } }
        ];
        attributes.forEach(attr => {
          this.addToStoreBuffer(attr);
        });
      }
      this.mergeInjectedIssue(this.task, issue);
      this.currentComponent = null;
    },
    openRequiredCFsPopup() {
      this.popUpCustomStyles = {
        position: "fixed !important",
        "min-height": `400px`,
        "max-width": "600px",
        left: " 50%",
        top: "50%",
        transform: "translate(-50%, -50%) !important",
        display: "flex"
      };
      this.currentComponent = "RequiredCustomFieldsPopup";
    }
  }
};
</script>
<style lang="scss" scoped></style>
