<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="modal-wrapper"
    :class="`${block}--no-sidebar`"
    :block="block"
    modificator="new"
    :previous-path-name="previousPathName"
    :previous-search="previousSearch"
    :on-close-fnc="onModalClose"
    :options="{ customStyles: 'max-width: 480px;' }"
  >
    <template slot="headline">
      <h2 class="vue-modal__headline ">
        <span v-if="options.single">{{ translations.label_issue_new }}</span>
        <NewEntitySelect
          v-else
          :bem="bem"
          :entity="entity"
          :translations="translations"
          :options="options"
          @entity:changed="$emit('entity:changed', $event)"
        />
      </h2>
    </template>
    <FirstStep
      slot="body"
      :new-issue="newIssue"
      :bem="bem"
      :show-errors="showErrors"
      :is-mobile="isMobile"
      :block="block"
      @close="openNewModal($event)"
    />
    <template slot="button-panel">
      <div class="vue-modal__button-panel">
        <button
          v-show="showSave"
          :class="{
            'button disabled': newIssue.errorsList.length !== 0,
            'button-positive': newIssue.errorsList.length === 0
          }"
          @click="save"
          @mouseenter="hover(true)"
          @mouseleave="hover(false)"
        >
          {{ translations.button_create }}
        </button>
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import NewEntitySelect from "../components/NewEntitySelect";
import FirstStep from "./newIssue/FirstStep.vue";

import locales from "../graphql/locales/issueProject";
import issueHelper from "../store/actionHelpers";
import axios from "axios";
import { allSettingsQueryWithoutProject } from "../graphql/allSettings";

export default {
  name: "NewIssueModal",
  components: { ModalWrapper, FirstStep, NewEntitySelect },
  props: {
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
    bemBlock: String,
    entity: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    },
    currentUser: {
      type: Object,
      default: () => {}
    },
    options: {
      type: Object,
      default: () => {}
    }
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
      id: "1",
      issueQuery: window.urlPrefix + "/issues",
      block: this.$props.bemBlock,
      actions: this.$props.actionButtons,
      buttonsTitle: ["Close"],
      currentComponent: null,
      top: 0,
      popUpOptions: [],
      popUpCustomStyles: {},
      excludedItems: [],
      sidebarOpen: false,
      showErrors: false,
      animated: false,
      alignment: {},
      currentData: {},
      previousPathName: "",
      previousSearch: "",
      subject: ""
    };
  },
  computed: {
    newIssue() {
      return this.$store.state.newIssue;
    },
    showSave() {
      return (
        this.newIssue.project.id !== null && this.newIssue.tracker.id !== null
      );
    }
  },
  created() {
    this.init();
    this.getCurrentUser();
  },
  methods: {
    async init() {
      const store = this.$store;
      this.setInitialState(store);
      await this.validateSchema(store);
      await this.getLocales(store);
      await this.fetchSettings();
      this.$set(this.$store.state, "newIssue", {
        authorId: EASY.currentUser.id,
        description: "",
        editCommentInput: "",
        errorsList: [],
        project: this.options.project || {
          id: null,
          name: ""
        },
        priority: {
          id: null,
          name: ""
        },
        requiredCustomFields: [],
        requiredFields: [],
        status: {
          id: null,
          name: ""
        },
        subject: "",
        tracker: {
          id: null,
          name: ""
        },
        subtaskForId: this.options.subtaskForId || ""
      });
      this.$store.state.showModal = true;
      document.body.classList.add("vueModalOpened");
    },
    hover(show) {
      if (this.$store.state.newIssue.errorsList.length !== 0 && show) {
        this.showErrors = true;
      } else {
        this.showErrors = false;
      }
    },
    onModalClose() {
      const evt = new CustomEvent("entityCreated", {
        cancelable: false,
        detail: { issue: this.$props.id }
      });
      document.dispatchEvent(evt);
      this.$store.replaceState(this.$store.state.initialState);
    },
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: allSettingsQueryWithoutProject
        },
        processFunc(array) {
          return issueHelper.transformArrayToObject(array);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async openNewModal(id) {
      const wrapper = this.$refs["modal-wrapper"];
      wrapper.closeModal();
      await this.$nextTick();
      EasyVue.showModal("issue", +id);
    },
    async getLocales(store) {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: locales
        },
        processFunc(data) {
          return issueHelper.getLocales(data);
        }
      };
      await store.dispatch("fetchStateValue", payload);
    },
    getAttributes() {
      const attributes = {
        project_id: this.newIssue.project.id,
        tracker_id: this.newIssue.tracker.id,
        status_id: this.newIssue.status.id,
        priority_id: this.newIssue.priority.d,
        author_id: this.authorId,
        subject: this.newIssue.subject,
        description: this.newIssue.description,
        parent_issue_id: this.newIssue.parentIssueId,
        custom_field_values: {}
      };
      if (this.newIssue.requiredCustomFields.length > 0) {
        this.newIssue.requiredCustomFields.forEach(val => {
          if (val.value) {
            attributes.custom_field_values[val.customField.id] = val.value;
          }
        });
      }
      if (this.newIssue.requiredFields.length > 0) {
        this.newIssue.requiredFields.forEach(val => {
          if (val.data.hasOwnProperty("id")) {
            attributes[val.name] = val.data.id;
          } else if (val.data.hasOwnProperty("value") && val.data.value) {
            attributes[val.name] = val.data.value;
          }
        });
      }
      return attributes;
    },
    async save() {
      if (this.newIssue.errorsList.length !== 0) return;
      const reqBody = {
        issue: this.getAttributes(),
      };
      if (this.newIssue.subtaskForId) {
        reqBody.subtask_for_id = this.newIssue.subtaskForId;
      }
      const setUrl = `${this.issueQuery}.json`;
      await axios
        .post(setUrl, reqBody)
        .then(response => {
          this.openNewModal(response.data.issue.id);
        })
        .catch(error => {
          this.prepareSaveErrors(error);
        });
    },
    async prepareSaveErrors(error) {
      let errorsList = [];
      if (error.response.data.errors.length > 0) {
        error.response.data.errors.forEach(error => {
          errorsList.push(error);
        });
      } else {
        errorsList.push(error.response.statusText);
      }
      const payload = {
        name: "errorsList",
        value: errorsList
      };
      await this.$store.dispatch("newIssueValidate", payload);
      this.noticeSaveErrors();
    },
    noticeSaveErrors() {
      this.showErrors = true;
      this.timer = setTimeout(() => {
        this.showErrors = false;
      }, 2000);
    }
  }
};
</script>

<style scoped></style>
