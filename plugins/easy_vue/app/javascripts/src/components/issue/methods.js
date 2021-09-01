import actionSubordinates from "../../store/actionHelpers";
import issuePrimaryQueryBuilder from "../../graphql/issue";
import issuePriorityEnum from "../../graphql/IssuePriorityEnum";
import markAsRead from "../../graphql/markAsRead";
import locales from "../../graphql/locales/issueProject";
import taskListItemQuery from "../../graphql/taskListItemQuery";
import watchersQuery from "../../graphql/awailableWatchers";
import { allSettingsQuery } from "../../graphql/allSettings";
import issueHelper from "../../store/actionHelpers";

import Vue from "vue";
const issueMethods = {
  onModalClose(fireEvent) {
    const buffer = this.$store.state.buffer;
    if (fireEvent) {
      const evt = new CustomEvent("vueModalIssueChanged", {
        cancelable: false,
        detail: {
          buffer,
          id: this.$props.id
        }
      });
      document.dispatchEvent(evt);
    }
    const options = {
      name: "shortcuts",
      value: [],
      level: "state"
    };
    this.$store.commit("setStoreValue", options);
  },
  async openNewModal(event) {
    const wrapper = this.$refs["modal-wrapper"];
    wrapper.closeModal();
    await this.$nextTick();
    EasyVue.showModal("issue", +event.id);
  },
  activeSideBarButtons(result) {
    const { ref, value } = result;
    const btn = this.activeItems.find(item => item.ref === ref);
    if (btn.active !== value) Vue.set(btn, "active", value);
  },
  listMore(payload, isMobile) {
    // show more button class needs to be in excluded to prevent closing popup on click
    this.excludedItems.push("list__show-more");
    this.getTags();
    const topOffset =
      payload.buttonElement.getBoundingClientRect().y -
      document.querySelector(".vue-modal__container").offsetTop;
    const options = {
      topOffs: topOffset,
      leftOffs: payload.buttonElement.offsetLeft
    };
    this.alignment = this.getAlignment(payload.event, options, isMobile);
    this.currentComponent = payload.popupType;
  },
  saveSubject(newSubject) {
    if (newSubject.inputValue === this.subject) return;
    if (this.$store.state.localSave) {
      this.saveValue(newSubject, "subject", "subject");
    }
    this.subject = newSubject.inputValue;
    const payload = {
      name: "subject",
      reqBody: {
        issue: {
          subject: this.subject
        }
      },
      value: {
        subject: this.subject
      },
      reqType: "patch",
      processFunc(type, message) {
        newSubject.showFlashMessage(type, message);
      }
    };
    this.$store.dispatch("actionsJudge", payload);
  },
  popUpClose() {
    this.currentComponent = null;
    this.popUpCustomStyles = {};
  },
  async getCurrentPopUpInner(name, e, isMobile) {
    if (typeof name !== "string") return;
    const componentName = name.charAt(0).toUpperCase() + name.slice(1);
    this.alignment = this.getAlignment(e, {}, isMobile);
    switch (name) {
      case "coworkers": {
        await this.getCoworkersData();
        break;
      }
      case "tags": {
        await this.getTags();
        break;
      }
      case "parentTasks": {
        await this.getParentTasksData();
        return;
      }
      case "relatedTasks": {
        await this.getRelatedTasksData();
        return;
      }
    }
    this.currentComponent = `${componentName}`;
  },
  async getCoworkersData() {
    const id = this.$store.state.issue.id;
    const term = null;
    const payload = {
      name: "newAvailableWatchers",
      query: watchersQuery(id, term)
    };
    await this.$store.dispatch("getFilteredArray", payload);
    this.popUpCustomStyles = { height: "auto" };
    this.popUpOptions = this.$store.state.newAvailableWatchers;
  },
  async getTags() {
    if (!this.$store.state.tags.length) {
      const request = new Request(
        `${window.urlPrefix}/easy_taggables/autocomplete.json`
      );
      const response = await fetch(request);
      const data = await response.json();
      const options = {
        value: data,
        name: "tags",
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
    }
    this.popUpOptions = this.$store.state.tags;
  },
  async getParentTasksData() {
    const payload = {
      name: "allAvailableParents",
      apolloQuery: {
        query: taskListItemQuery("allAvailableParents", null),
        variables: { id: this.task.id }
      }
    };
    await this.$store.dispatch("fetchIssueValue", payload);
    this.popUpOptions = {
      tasks: this.parentTaskList,
      data: {
        inherited: this.buttons.find(item => item.ref === "parentTasks"),
        settings: {
          name: "parentTasks",
          queryName: "allAvailableParents",
          issuePropName: "ancestors",
          heading: this.translations.field_parent_issue,
          action: "addParent",
          multiselect: false
        }
      }
    };
    this.popUpCustomStyles = {
      maxWidth: "700px",
      height: "39%"
    };
    this.currentComponent = "TaskListPopUp";
  },
  async getRelatedTasksData() {
    const payload = {
      name: "allAvailableRelations",
      apolloQuery: {
        query: taskListItemQuery("allAvailableRelations", null),
        variables: { id: this.task.id }
      }
    };
    await this.$store.dispatch("fetchIssueValue", payload);
    this.popUpOptions = {
      tasks: this.relatedTaskList,
      data: {
        inherited: this.buttons.find(item => item.ref === "relatedTasks"),
        settings: {
          name: "relatedTasks",
          queryName: "allAvailableRelations",
          issuePropName: "relations",
          heading: this.translations.label_related_issues,
          action: "addRelation",
          multiselect: true,
          selectOptionsArray: this.$store.state.issue.allIssueRelationTypes
        }
      }
    };
    this.popUpCustomStyles = {
      maxWidth: "700px",
      height: "39%"
    };
    this.currentComponent = "TaskListPopUp";
  },
  async init() {
    const store = this.$store;
    this.setInitialState(store);
    this.showBackdrop(true);
    // fetch data
    await this.validateSchema(store);
    if (!store.state.injectedIssue) {
      await this.getIssue(store);
    } else {
      const payload = {
        name: "issue",
        attrs: store.state.injectedIssue,
        ignoreErr: true,
        level: "state"
      };
      await this.$store.dispatch("validate", payload);
    }
    if (!this.task) {
      this.showBackdrop(false);
      return;
    }
    await this.getEnumerations(store);
    await this.getLocales(store);
    await this.fetchSettings();
    // open modal
    this.subject = store.state.issue.subject;
    this.openModal();
    document.body.classList.add("vueModalOpened");
    this.markAsRead();
  },
  async markAsRead() {
    const payload = {
      mutationName: "markAsRead",
      apolloMutation: {
        mutation: markAsRead,
        variables: {
          entityId: this.task.id,
          entityType: "Issue"
        }
      },
      noNotification: true
    };
    this.$store.dispatch("mutateValue", payload);
  },
  async fetchSettings() {
    const payload = {
      name: "allSettings",
      apolloQuery: {
        query: allSettingsQuery,
        variables: {
          id: this.task.project.id
        }
      },
      processFunc(array) {
        return issueHelper.transformArrayToObject(array);
      }
    };
    await this.$store.dispatch("fetchStateValue", payload);
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
          id: this.id
        }
      }
    };
    await store.dispatch("fetchStateValue", payload);
    const injectedIssue = store.state.injectedIssue;
    if (injectedIssue) {
      this.mergeInjectedIssue(store.state.issue, injectedIssue);
    }
  },
  async getEnumerations(store) {
    const payload = {
      name: "allEnumerations",
      apolloQuery: {
        query: issuePriorityEnum
      }
    };
    await store.dispatch("fetchStateValue", payload);
  },
  async getLocales(store) {
    const payload = {
      name: "allLocales",
      apolloQuery: {
        query: locales
      },
      processFunc(data) {
        return actionSubordinates.getLocales(data);
      }
    };
    await store.dispatch("fetchStateValue", payload);
  },
  toggleFavorite() {
    const task = this.task;
    const payload = {
      name: "isFavorite",
      value: {
        isFavorite: !task.isFavorite
      },
      reqType: "post",
      reqBody: {},
      url: `${window.urlPrefix}/easy_issues/${task.id}/favorite.json`
    };
    this.$store.dispatch("saveIssueStateValue", payload);
    this.animated = true;
  },
  openModal() {
    const payloadShow = {
      name: "showModal",
      value: true,
      level: "state"
    };
    this.$store.commit("setStoreValue", payloadShow);
    const evt = new CustomEvent("vueModalIssueOpened", {
      cancelable: false,
      detail: { issue: this.$props.id }
    });
    document.dispatchEvent(evt);
  },
  togglePrivate() {
    const task = this.task;
    const payload = {
      name: "isPrivate",
      value: {
        isPrivate: !task.isPrivate
      },
      reqType: "patch",
      reqBody: {
        issue: {
          is_private: task.isPrivate ? "0" : "1"
        }
      },
      level: "issue"
    };
    this.$store.dispatch("saveIssueStateValue", payload);
  },
  mergeInjectedIssue(target, obj) {
    let value = target;
    if (obj) {
      value = this.objMerge(target, obj);
    }
    const payload = {
      name: "issue",
      value,
      level: "state"
    };
    this.$store.commit("setStoreValue", payload);
  },
  confirm(e) {
    this.action.func = e.action;
    this.action.close = e.close;
    this.showConfirm(e.eventData, this.$props.isMobile);
  },
  showConfirm(e, isMobile) {
    const options = {
      topOffs: 20,
      rightOffs: 15
    };
    this.popUpCustomStyles = {
      width: "auto",
      height: "95px !important",
      display: "flex",
      "align-items": "center"
    };
    this.alignment = this.getAlignment(e, options, isMobile);
    this.currentComponent = "Confirm";
  },
  closePopUp() {
    this.currentComponent = null;
  },
  confirmAction(value) {
    const wrapper = this.$refs["modal-wrapper"];
    if (value) {
      this.action.func();
      if (this.action.close) {
        if (this.timer) clearTimeout(this.timer);
        // For scheduler allocation delete
        // If we close modal earlier its not gonna delete it
        this.timer = setTimeout(() => {
          wrapper.closeModal();
        }, 2000);
      }
    }
    this.closePopUp();
  },
  reallocateSpentTime(e) {
    const issue = this.$store.state.issue;
    const isSpentTime = issue.timeEntries ? !!issue.timeEntries.length : false;
    const isSpentTimeSubtasks = issue.descendants
        ? !!issue.descendants.find(({ timeEntries }) => timeEntries.length > 0)
        : false;
    if (isSpentTime || isSpentTimeSubtasks) {
      const options = {
        topOffs: 20,
        rightOffs: 15
      };
      this.popUpCustomStyles = {
        width: "auto",
        height: "230px !important",
        display: "flex",
        "align-items": "center",
        "max-width": "550px"
      };
      this.popUpOptions = [];
      this.alignment = this.getAlignment(e, options, this.$props.isMobile);
      this.currentComponent = "ReallocateSpentTime";
      this.action.func = () => {
        const wrapper = this.$refs["modal-wrapper"];
        wrapper.closeModal();
        this.currentComponent = null;
      };
      return;
    }
    this.action.func = async () => {
      return await this.deleteTask();
    };
    this.showConfirm(e);
  },
  async deleteTask() {
    const req = new Request(`${window.urlPrefix}/issues/${this.task.id}.json`);
    await fetch(req, { method: "DELETE" });
    const wrapper = this.$refs["modal-wrapper"];
    if (this.$store.state.localSave) {
      const payload = {
        prop: {
          name: "delete",
          value: true
        }
      };
      this.addToStoreBuffer(payload);
    }
    wrapper.closeModal();
    this.currentComponent = null;
  },
  handleFileDrop(e) {
    const issueCompRef = this.$refs?.issueContentComponent;
    const attachmentsCompRef = issueCompRef?.$refs?.attachmentsComponent;
    attachmentsCompRef?.handleAttachmentLoad?.(e);
  }
};

export default issueMethods;
