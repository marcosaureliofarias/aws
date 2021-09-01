<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    :block="'vue-modal'"
    :previous-path-name="previousPathName"
    :previous-search="previousSearch"
  >
    <template slot="headline">
      <h2 class="vue-modal__headline ">
        <InlineInput
          :id="id"
          :data="subjectInput"
          :value="subject"
          @child-value-change="saveSubject($event, 'hostname', 'hostname')"
        />
      </h2>
    </template>
    <template slot="body">
      <Detail
        :id="id"
        :bem="bem"
        :on-premise-application="onPremiseApplication"
        :translations="translations"
      />
      <Description
        :entity="onPremiseApplication"
        :bem="bem"
        :editable="onPremiseApplication.editable"
        @save="saveDescription"
      />
      <Comments
        :journals="journals"
        :bem="bem"
        :permissions="commentsPermissions"
        @add-comment="createJournal"
      />
    </template>
    <Sidebar
      slot="sidebar"
      :active="buttons"
      :actions="actionButtons"
      :reference="`#${id}`"
      :bem="bem"
      :custom-url="customUrl"
    />
  </ModalWrapper>
</template>

<script>
import Comments from "./issue/Comments";

import ModalWrapper from "./generalComponents/Wrapper";
import {
  onPremiseApplicationQuery,
  onPremiseApplicationJournals
} from "../graphql/onPremiseApplication";
import Detail from "./onPremiseApplication/Detail";
import Description from "./generalComponents/Description";
import actionSubordinates from "../store/actionHelpers";
import locales from "../graphql/locales/opa";
import Sidebar from "./generalComponents/Sidebar";
import {
  onPremiseApplicationPatch,
  createUpdateJournal
} from "../graphql/mutations/onPremiseApplication";
import InlineInput from "./generalComponents/InlineInput";
import apollo from "../apolloClient";

export default {
  name: "OpaModal",
  components: {
    Comments,
    Sidebar,
    Description,
    Detail,
    ModalWrapper,
    InlineInput
  },
  props: {
    id: [String, Number],
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
      previousPathName: "",
      previousSearch: ""
    };
  },
  computed: {
    onPremiseApplication: {
      get() {
        return this.$store.state.onPremiseApplication;
      }
    },
    customUrl() {
      return `${window.urlPrefix}/easy_on_premise_applications/${this.onPremiseApplication.id}`;
    },
    buttons() {
      return [
        {
          name: this.translations.label_details,
          anchor: "#detail",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.translations.field_description,
          anchor: "#description_anchor",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.translations.label_comment_plural,
          anchor: "#comments_anchor",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        }
      ];
    },
    translations() {
      return this.$store.state.allLocales;
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
        editable: this.onPremiseApplication.editable
      };
    },
    subject() {
      const opa = this.$store.state.onPremiseApplication;
      if (!opa) return "";
      return opa.hostname;
    },
    commentsPermissions() {
      return {
        addableNotes: this.onPremiseApplication.editable
      };
    },
    journals() {
      const journals = this.onPremiseApplication.journals;
      return journals ? journals : [];
    }
  },
  created() {
    // set onPremiseApplication to store to be reactive, its because we dont want to have too many objects in root store
    // when we are not using them.
    this.$set(this.$store.state, "onPremiseApplication", {});
    this.openModal();
  },
  methods: {
    async openModal() {
      await this.fetchOpaData();
      await this.getLocales();
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state"
      };
      this.$store.commit("setStoreValue", payloadShow);
      this.previousPathName = window.location.pathname;
      this.previousSearch = window.location.search;
      window.history.pushState({}, null, this.customUrl);
    },
    async fetchOpaData() {
      // Fetch and set OPA data to store
      const payload = {
        name: "onPremiseApplication",
        apolloQuery: {
          query: onPremiseApplicationQuery,
          variables: { id: this.$props.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: locales
        },
        processFunc(data) {
          return actionSubordinates.getLocales(data);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async saveDescription(newValue) {
      const payload = {
        mutationName: "onPremiseApplicationUpdate",
        apolloMutation: {
          mutation: onPremiseApplicationPatch,
          variables: {
            entityId: this.id,
            attributes: { description: newValue }
          }
        },
        pathToGet: [
          "onPremiseApplicationUpdate",
          "easyOnPremiseApplication",
          "description"
        ],
        pathToSet: ["onPremiseApplication", "description"]
      };
      await this.$store.dispatch("mutateValue", payload);
    },
    async saveSubject(event, requestName, storeName) {
      const payload = {
        mutationName: "onPremiseApplicationUpdate",
        apolloMutation: {
          mutation: onPremiseApplicationPatch,
          variables: {
            entityId: this.id,
            attributes: { [requestName]: event.inputValue }
          }
        },
        pathToGet: [
          "onPremiseApplicationUpdate",
          "easyOnPremiseApplication",
          storeName
        ],
        pathToSet: ["onPremiseApplication", storeName],
        processFunc: event.showFlashMessage
      };
      await this.$store.dispatch("mutateValue", payload);
      const options = {
        name: "hostname",
        value: event.inputValue,
        level: "onPremiseApplication"
      };
      this.$store.commit("setStoreValue", options);
    },
    async getSetJournals(all) {
      const response = await apollo.query({
        query: onPremiseApplicationJournals,
        variables: {
          id: this.onPremiseApplication.id,
          all: all
        }
      });
      const newJournals = response.data.onPremiseApplication.journals;
      const commitOptions = {
        name: "journals",
        value: newJournals,
        level: "onPremiseApplication"
      };
      await this.$store.commit("setStoreValue", commitOptions);
    },
    async createJournal(event) {
      const payload = {
        mutationName: "journalChange",
        apolloMutation: {
          mutation: createUpdateJournal,
          variables: {
            entityId: this.onPremiseApplication.id,
            entityType: "EasyOnPremiseApplication",
            notes: event.inputValue
          }
        }
      };
      await this.$store.dispatch("mutateValue", payload);
      this.getSetJournals(false);
    }
  }
};
</script>

<style scoped></style>
