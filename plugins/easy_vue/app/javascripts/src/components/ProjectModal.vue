<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="modal-wrapper"
    :block="'vue-modal'"
    :on-close-fnc="onModalClose"
  >
    <template slot="headline">
      <h2 :class="bem.ify(bem.block, 'headline') + ' color-scheme-modal '">
        <InlineInput
          :id="project.id"
          :data="subjectInput"
          :value="subject"
          @child-value-change="saveSubject($event)"
        />
      </h2>
    </template>
    <ProjectContent
      slot="body"
      :bem="bem"
      :project="project"
      :translations="translations"
    />
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
import actionSubordinates from "../store/actionHelpers";
import projectPrimaryQueryBuilder from "../graphql/project";
import InlineInput from "./generalComponents/InlineInput";
import { allSettingsQuery } from "../graphql/allSettings";
import locales from "../graphql/locales/issueProject";
import issueHelper from "../store/actionHelpers";
import ModalWrapper from "./generalComponents/Wrapper";
import ProjectContent from "./project/ProjectContent";
import Sidebar from "./generalComponents/Sidebar";

export default {
  name: "ProjectModal",
  components: { ModalWrapper, InlineInput, ProjectContent, Sidebar },
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
      subject: ""
    };
  },
  computed: {
    subjectInput() {
      return {
        labelName: "subject",
        classes: {
          edit: ["u-editing"],
          show: ["u-showing editable-input__wrapper--subject"]
        },
        inputType: "text",
        withSpan: true,
        editable: true
      };
    },
    translations() {
      return this.$store.state.allLocales;
    },
    project() {
      return this.$store.state.project;
    },
    buttons() {
      if (!this.project || !this.translations) return [];
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
          name: "Member",
          anchor: "#member_list",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.translations.label_history,
          anchor: "#history",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        }
      ];
    },
    customUrl() {
      return `${window.urlPrefix}/projects/${this.project.id}`;
    }
  },
  created() {
    this.$set(this.$store.state, "onPremiseApplication", {});
    this.init();
  },
  methods: {
    async init() {
      const store = this.$store;
      this.setInitialState(store);
      // fetch data
      await this.validateSchema(store);
      await this.getProject(store);
      await this.getLocales(store);
      await this.fetchSettings(store);
      //this.project = await store.state.project;
      // open modal
      this.subject = this.$store.state.project.name;
      this.openModal();
      document.body.classList.add("vueModalOpened");
      document.addEventListener("keyup", this.closeOnEscape);
    },
    async getProject(store) {
      const payload = {
        name: "project",
        apolloQuery: {
          query: projectPrimaryQueryBuilder(),
          variables: {
            id: this.id
          }
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
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: allSettingsQuery,
          variables: {
            id: this.$props.id
          }
        },
        processFunc(array) {
          return issueHelper.transformArrayToObject(array);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    openModal() {
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state"
      };
      this.$store.commit("setStoreValue", payloadShow);
      const evt = new CustomEvent("vueModalProjectOpened", {
        cancelable: false,
        detail: { project: this.project.id }
      });
      document.dispatchEvent(evt);
    },
    saveSubject(newSubject) {
      if (newSubject.inputValue === this.subject) return;
      this.subject = newSubject.inputValue;
      const payload = {
        name: "name",
        reqBody: {
          project: {
            name: this.subject
          }
        },
        value: {
          name: this.subject
        },
        reqType: "patch",
        processFunc(type, message) {
          newSubject.showFlashMessage(type, message);
        }
      };
      this.$store.dispatch("saveProjectStateValue", payload);
    },
    onModalClose() {
      const evt = new CustomEvent("vueModalProjectChanged", {
        cancelable: false,
        detail: { project: this.$props.id }
      });
      document.dispatchEvent(evt);
    }
  }
};
</script>

<style scoped></style>
