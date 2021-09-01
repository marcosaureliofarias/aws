<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    :id="id"
    ref="modal-wrapper"
    :block="block"
    :previous-path-name="previousPathName"
    :previous-search="previousSearch"
    :on-close-fnc="onModalClose"
    :entity-type="entityType"
    :enable-file-drag-and-drop="true"
    :translations="translations"
    @wrapper:file-drop="handleFileDrop"
  >
    <template slot="headline">
      <h2 :class="headlineClasses">
        <InlineInput
          :id="task.id"
          :data="subjectInput"
          :value="subject"
          @child-value-change="saveSubject($event)"
        />
        <div :class="`${bem.ify(block, 'icons')}`">
          <a
            v-if="
              task.setIsPrivate &&
                $store.state.allSettings.enable_private_issues
            "
            :title="$store.state.allLocales.field_is_private"
            class="icon icon-watcher"
            :class="{ private: task.isPrivate }"
            href="#"
            @click.prevent="togglePrivate"
          />
          <a
            :title="$store.state.allLocales.label_favorite"
            :class="favoriteClasses"
            href="#"
            @click="toggleFavorite"
            @animationend="animated = false"
          />
        </div>
      </h2>
    </template>
    <IssueContent
      slot="body"
      ref="issueContentComponent"
      :bem="bem"
      :task="task"
      :active-btns="buttons"
      :is-mobile="isMobile"
      :block="block"
      :additional-rights="additionalRights"
      @list-more="listMore($event, isMobile)"
      @close="openNewModal($event)"
      @taskListChecked="activeSideBarButtons($event)"
    />
    <Sidebar
      slot="sidebar"
      :active="buttons"
      :actions="actionBtns"
      :reference="`#${id}`"
      :bem="bem"
      :custom-url="customUrl"
      :is-mobile="isMobile"
      @confirm="confirm($event)"
    >
      <PopUp
        v-if="currentComponent && popUpOptions"
        slot="popup"
        :bem="bem"
        :align="alignment"
        :task="task"
        :component="currentComponent"
        :options="popUpOptions"
        :extra-data="currentData"
        :excluded-items="excludedItems"
        :custom-styles="popUpCustomStyles"
        :translations="$store.state.allLocales"
        :is-mobile="isMobile"
        @onBlur="popUpClose"
        @confirmed="confirmAction($event)"
      />
    </Sidebar>
  </ModalWrapper>
  <ModalBackdrop v-else-if="activeBackdrop" :block="block" :bem="bem" />
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import ModalBackdrop from "./generalComponents/ModalBackdrop";
import InlineInput from "./generalComponents/InlineInput";
import PopUp from "./generalComponents/PopUp";
import IssueContent from "./issue/IssueContent";
import Sidebar from "./generalComponents/Sidebar";
import methods from "./issue/methods";

export default {
  name: "IssueModal",
  components: { InlineInput, ModalWrapper, IssueContent, Sidebar, PopUp, ModalBackdrop },
  props: {
    id: {
      type: [String, Number]
    },
    actionButtons: {
      type: Array,
      default() {
        return [];
      }
    },
    isMobile: {
      type: Boolean,
      default: false
    },
    injectedIssue: {
      type: Object,
      default: () => {}
    },
    additionalRights: {
      type: Object,
      default: () => {}
    },
    entityType: {
      type: String,
      default: () => ""
    },
    activeBackdrop: {
      type: Boolean,
      default: () => false
    },
    bemBlock: String
  },
  data() {
    return {
      bem: {
        block: this.$props.bemBlock,
        ify: function(b, e, m) {
          let output = b;
          output += e ? "__" + e : "";
          output = m ? output + " " + output + "--" + m : output;
          return output.toLowerCase();
        }
      },
      locales: this.$store.state.allLocales,
      block: this.$props.bemBlock,
      actions: this.$props.actionButtons,
      buttonsTitle: ["Close"],
      currentComponent: null,
      top: 0,
      popUpOptions: [],
      popUpCustomStyles: {},
      excludedItems: [],
      sidebarOpen: false,
      animated: false,
      alignment: {},
      currentData: {},
      previousPathName: "",
      previousSearch: "",
      subject: "",
      action: {}
    };
  },
  computed: {
    headlineClasses() {
      let classString = "";
      classString +=
        this.bem.ify(this.bem.block, "headline") +
        " color-scheme-modal " +
        this.task.priority.easyColorScheme;
      return classString;
    },
    favoriteClasses() {
      return {
        "icon icon-fav favorited vue-modal-icon-favorite": this.task.isFavorite,
        "icon icon-fav-off vue-modal-icon-favorite": !this.task.isFavorite,
        "pulse-active": this.animated
      };
    },
    actionBtns() {
      const defaultButtons = this.issueDefaultButtons.filter(
        item => item.enabled
      );
      const buttons = [...this.$props.actionButtons, ...defaultButtons];
      return buttons;
    },
    subjectInput() {
      return {
        labelName: "subject",
        classes: {
          edit: ["u-editing"],
          show: ["u-showing editable-input__wrapper--subject"]
        },
        inputType: "text",
        withSpan: true,
        editable: this.task.editable && this.workFlowChangable("subject")
      };
    },
    task: {
      get() {
        return this.$store.state.issue;
      },
      set(newValue) {
        const options = {
          value: newValue,
          level: "state"
        };
        this.$store.commit("setStoreValue", options);
      }
    },
    activeItems: {
      get() {
        const active = this.buttons.filter(item => item.isModuleActive);
        return active;
      }
    },
    parentTaskList() {
      return this.task.allAvailableParents;
    },
    relatedTaskList() {
      return this.task.allAvailableRelations;
    },
    translations() {
      return this.$store.state.allLocales;
    },
    buttons() {
      if (!this.task && !this.task.poject) return [];
      return [
        {
          name: this.$store.state.allLocales.label_details,
          anchor: "#detail",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.field_description,
          anchor: "#description_anchor",
          active: true,
          isModuleActive: this.showByTracker("description"),
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.label_comment_plural,
          anchor: "#comments_anchor",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.easy_git_heading_easy_git,
          anchor: "#merge_requests_anchor",
          active: true,
          isModuleActive: this.showMergeRequests(),
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.label_issue_attachments_heading,
          anchor: "#attachments_anchor",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.label_spent_time,
          anchor: "#spent_time_anchor",
          active: true,
          isModuleActive: this.isModuleEnabled("time_tracking"),
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.field_watcher,
          anchor: "",
          active: true,
          isModuleActive: this.task.watchers,
          ref: "coworkers",
          showAddAction: true,
          onClick: this.getCurrentPopUpInner
        },
        {
          name: this.$store.state.allLocales.label_easy_checklist_plural,
          anchor: "#checklist_anchor",
          active: true,
          isModuleActive:
            this.isModuleEnabled("easy_checklists") &&
            this.task.project.visibleChecklists,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.label_easy_tags,
          anchor: "",
          active: true,
          isModuleActive: true,
          ref: "tags",
          showAddAction: true,
          onClick: this.getCurrentPopUpInner
        },
        {
          name: this.$store.state.allLocales.label_subtask_plural,
          anchor: "#subtasks_anchor",
          active: false,
          isModuleActive: true,
          ref: "subtasks",
          showAddAction: this.task.editable && (!this.additionalRights || this.additionalRights.addSubTasks)
            && this.task.manageSubtasks,
          onClick: async () => {
            const subtaskForId = this.task.id;
            const range = { start: new Date() };
            const project = this.task.project;
            this.$refs["modal-wrapper"].closeModal(false);
            await this.$nextTick();
            EasyVue.showModal("new_issue", null, { single: true, range, subtaskForId, project });
          }
        },
        {
          name: this.$store.state.allLocales.field_parent_issue,
          anchor: "#parentTasks_anchor",
          active: false,
          isModuleActive: true,
          ref: "parentTasks",
          showAddAction: this.task.editable && this.workFlowChangable("parent_issue_id") &&
            (!this.additionalRights || this.additionalRights.addParentTasks),
          onClick: this.getCurrentPopUpInner
        },
        {
          name: this.$store.state.allLocales.label_related_issues,
          anchor: "#relatedTasks_anchor",
          active: false,
          isModuleActive: true,
          ref: "relatedTasks",
          showAddAction: this.task.editable && (!this.additionalRights || this.additionalRights.addRelatedTasks),
          onClick: this.getCurrentPopUpInner
        }
      ];
    },
    issueDefaultButtons() {
      return [
        {
          name: this.$store.state.allLocales.button_copy,
          func: () => {
            const url = `${window.urlPrefix}/projects/${this.task.project.id}/issues/${this.task.id}/copy`;
            window.open(url, "_blank");
          },
          enabled: this.task.copyIssues
        },
        {
          name: this.$store.state.allLocales.sidebar_issue_button_delete,
          func: async (params, triggeredComp, event) => {
            this.reallocateSpentTime(event);
          },
          closeAfterEvent: true,
          needConfirm: false,
          enabled: this.task.deletable
        },
        {
          name: this.$store.state.allLocales.button_move,
          func: () => {
            const url = `${window.urlPrefix}/issues/bulk_edit?ids=${this.task.id}`;
            window.open(url, "_self");
          },
          enabled: this.task.moveIssues
        },
        {
          name: this.$store.state.allLocales.button_clone_as_subtask,
          func: () => {
            const id = this.task.id;
            // eslint-disable-next-line max-len
            const url = `${window.urlPrefix}/projects/${this.task.project.id}/issues/${id}/copy?copy_subtask=false&subtask_for_id=${id}`;
            window.open(url, "_blank");
          },
          enabled: this.task.add_issues
        }
      ];
    },
    customUrl() {
      return `${window.urlPrefix}/issues/${this.task.id}`;
    }
  },
  created() {
    this.$set(this.$store.state, "issue", { watchers: [] });
    this.init();
    this.getCurrentUser();
    this.allowShortcuts();
  },
  methods: methods
};
</script>

<style scoped></style>
