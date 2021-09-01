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
        <NewEntitySelect
          :bem="bem"
          :entity="entity"
          :translations="translations"
          @entity:changed="$emit('entity:changed', $event)"
        />
      </h2>
    </template>
    <NewAllocationContent
      slot="body"
      :bem="bem"
      :new-allocation="newAllocation"
      :show-errors="showErrors"
    />
    <template slot="button-panel">
      <div class="vue-modal__button-panel">
        <button
          v-show="showSave"
          :class="{
            'button disabled': newAllocation.errorsList.length !== 0,
            'button-positive': newAllocation.errorsList.length === 0
          }"
          @click="save"
          @mouseenter="hover(true)"
          @mouseleave="hover(false)"
        >
          Create
        </button>
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import locales from "../graphql/locales/allocation";
import issueHelper from "../store/actionHelpers";
import { allSettingsQueryWithoutProject } from "../graphql/allSettings";
import NewAllocationContent from "./newAllocation/NewAllocationContent";
import newAllocation from "../graphql/mutations/newAllocation";
import NewEntitySelect from "../components/NewEntitySelect";

export default {
  name: "NewAllocationModal",
  components: { NewAllocationContent, ModalWrapper, NewEntitySelect },
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
    newAllocation() {
      return this.$store.state.newEasyGanttResource;
    },
    showSave() {
      return this.newAllocation.issue !== null;
    }
  },
  created() {
    this.init();
    this.getCurrentUser();
  },
  methods: {
    async init() {
      const options = this.$props.options;
      const store = this.$store;
      let date = null;
      let start = null;
      let end = null;
      if (options.hasOwnProperty("range")){
        date = options.range.start;
        start = this.getTimeFromDate(options.range.start);
        end = this.getTimeFromDate(options.range.end);
      }
      this.setInitialState(store);
      await this.validateSchema(store);
      await this.getLocales(store);
      await this.fetchSettings();
      this.$set(this.$store.state, "newEasyGanttResource", {
        custom: true,
        date: date,
        hours: null,
        issue: null,
        endTime: end,
        startTime: start,
        errorsList: []
      });
      this.$store.state.showModal = true;
      document.body.classList.add("vueModalOpened");
    },
    hover(show) {
      if (this.newAllocation.errorsList.length !== 0 && show) {
        this.showErrors = true;
      } else {
        this.showErrors = false;
      }
    },
    onModalClose() {
      /*zatim issue changed abych nemusel menit scheduler :D*/
      const evt = new CustomEvent("vueModalIssueChanged", {
        cancelable: false,
        detail: {}
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
    async save() {
      if (this.newAllocation.errorsList.length !== 0) return;
      const payload = {
        hours: this.newAllocation.hours,
        start: this.newAllocation.startTime,
        date: this.newAllocation.date,
        user_id: this.$store.state.user.id,
        custom: true,
        issue_id: this.newAllocation.issue ? this.newAllocation.issue.id : null
      };
      const mutationPayload = {
        mutationName: "easyGanttResource",
        apolloMutation: {
          mutation: newAllocation,
          variables: {
            attributes: payload
          }
        }
      };
      const response = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );

      const easyGanttResource = response.data.easyGanttResource;
      const errors = easyGanttResource.errors;
      if (errors.length) {
        this.prepareSaveErrors(errors);
      } else {
        const wrapper = this.$refs["modal-wrapper"];
        wrapper.closeModal();
      }
    },
    async prepareSaveErrors(errors) {
      const saver = {};
      let errorsList = [];
      errors.forEach(val => {
        val.fullMessages.forEach(mess => {
          errorsList.push(mess);
        });
      });
      saver.errorsList = errorsList;
      const value = { ...this.$store.state.newEasyGanttResource, ...saver };
      const options = {
        name: "newEasyGanttResource",
        value: value,
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
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
