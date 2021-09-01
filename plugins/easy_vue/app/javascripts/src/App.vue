<template>
  <div id="app" :style="styleObject">
    <NewEntityModal
      v-if="isNewModal"
      :id="entityID"
      :entity-type="entity"
      :bem-block="bemBlock"
      :options="options"
      :is-mobile="isMobile"
    />
    <IssueModal
      v-if="entityType === 'issue'"
      :id="entityID"
      :entity-type="entityType"
      :additional-issue="options.injectedIssue"
      :additional-rights="options.rights"
      :action-buttons="actions"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
      :active-backdrop="activeBackdrop"
    />
    <ProjectModal
      v-if="entityType === 'project'"
      :id="entityID"
      :action-buttons="actions"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
    />
    <OpaModal
      v-if="entityType === 'opa'"
      :id="entityID"
      :action-buttons="actions"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
    />
    <ContractModal
      v-if="entityType === 'contract'"
      :id="entityID"
      :action-buttons="actions"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
    />
    <AttendanceModal
      v-if="entityType === 'easy_attendance'"
      :id="entityID"
      :action-buttons="actions"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
    />
    <MeetingModal
      v-if="entityType === 'meeting'"
      :id="entityID"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
      :options="options"
    />
    <EmptyModal
      v-if="entityType === 'empty'"
      :bem-block="bemBlock"
      :action-buttons="actions"
      :show-button-bar="buttonBar"
      :options="options"
    />
    <SalesActivityModal
      v-if="entityType === 'easy_entity_activity'"
      :id="entityID"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
    />
    <ExternalEventModal
      v-if="entityType === 'ical_event'"
      :id="entityID"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
    />
    <AllocationModal
      v-if="entityType === 'allocation'"
      :id="entityID"
      :bem-block="bemBlock"
      :action-buttons="actions"
      :options="options"
    />
    <AcquisitionModal
      v-if="entityType === 'acquisition'"
      :id="entityID"
    />
    <EditQuoteModal
      v-if="entityType === 'edit_quote'"
      :id="entityID"
    />
  </div>
</template>
<script>
import ProjectModal from "./components/ProjectModal";
import OpaModal from "./components/OpaModal";
import IssueModal from "./components/IssueModal";
import ContractModal from "./components/ContractModal";
import MeetingModal from "./components/MeetingModal";
import EmptyModal from "./components/EmptyModal";
import AttendanceModal from "./components/AttendanceModal";
import SalesActivityModal from "./components/SalesActivityModal";
import ExternalEventModal from "./components/ExternalEventModal";
import AllocationModal from "./components/AllocationModal";
import NewEntityModal from "./components/NewEntityModal";
import AcquisitionModal from "./components/AcquisitionModal";
import EditQuoteModal from "./components/EditQuoteModal";
export default {
  name: "App",
  components: {
    EmptyModal,
    ContractModal,
    IssueModal,
    ProjectModal,
    OpaModal,
    AttendanceModal,
    MeetingModal,
    SalesActivityModal,
    ExternalEventModal,
    NewEntityModal,
    AllocationModal,
    AcquisitionModal,
    EditQuoteModal
  },
  props: {
    entityType: String,
    entityID: [String, Number],
    options: {
      type: Object,
      default() {
        return {
          localSave: false,
          injectedIssue: null,
          rights: {}
        };
      }
    }
  },
  data() {
    return {
      bemBlock: "vue-modal",
      isMobile: false,
      buttonBar: this.options.hasOwnProperty("buttonBar")
        ? this.options.buttonBar
        : true,
      actions: this.options.hasOwnProperty("actions")
        ? this.options.actions
        : [],
      styleObject: {
        "z-index": EASY.utils.modalOpened
          ? Number(EASY.getSassData("modal-zindex")) + 2
          : "",
        position: "relative"
      },
      entity: this.$props.entityType
    };
  },
  computed: {
    isNewModal() {
      if (this.entityType.startsWith("new")) return true;
      return false;
    },
    activeBackdrop() {
      return !this.$store.state.showModal && this.$store.state.backdrop;
    }
  },
  async created() {
    await this.initialSet();
  },
  methods: {
    async initialSet() {
      if (this.$props.options.injectedIssue) {
        await this.setInjectedIssue();
      }
      await this.setIsMobile();
      await this.setIsSaving();
      this.setOldModalsStyle("none");
      if (this.$props.options.rights) await this.setAdditionalRights();
    },
    async setIsMobile() {
      const options = {
        name: "isMobile",
        value: ERUI.isMobile,
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
      this.isMobile = ERUI.isMobile;
    },
    async setIsSaving() {
      const options = {
        name: "localSave",
        value: this.$props.options.localSave,
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
    },
    async setInjectedIssue() {
      const options = {
        name: "injectedIssue",
        value: this.$props.options.injectedIssue,
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
    },
    async setAdditionalRights() {
      const payload = {
        name: "additionalRights",
        value: this.$props.options.rights,
        level: "state"
      };
      await this.$store.commit("setStoreValue", payload);
    }
  }
};
</script>

<style lang="scss">
@import "./stylesheets/main.scss";
</style>
