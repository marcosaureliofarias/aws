<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="wrapper"
    :modificator="`attendance ${withButtonPanel}`"
    :block="block"
    :on-close-fnc="dispatchModalChange"
  >
    <template slot="headline">
      <h2 :class="bem.ify(bem.block, 'headline')">
        {{ attendance.easyAttendanceActivity.name }}
      </h2>
    </template>
    <template slot="body">
      <Detail
        :bem="bem"
        :data="attendance"
        :translations="translations"
        :is-mobile="isMobile"
        :block="block"
        @save-value="save($event)"
        @change-range="changeRange($event)"
      />
      <Description
        :bem="bem"
        :editable="attendance.canEdit"
        :textile="textile"
        :entity="attendance"
        @save="saveDescription($event)"
      />
      <History
        v-if="formatedActivities.length"
        :activities="formatedActivities"
        :translations="translations"
        :bem="bem"
      />
    </template>
    <Sidebar
      slot="sidebar"
      :active="sidebarButtons"
      :bem="bem"
      :is-mobile="isMobile"
      @confirm="confirm($event)"
    >
      <PopUp
        v-if="currentComponent"
        slot="popup"
        :bem="bem"
        :align="alignment"
        :component="currentComponent"
        :custom-styles="custom"
        :options="popUpOptions"
        :translations="translations"
        @onBlur="closePopUp"
        @confirmed="confirmAction"
      />
    </Sidebar>
    <template slot="button-panel">
      <div v-if="buttonsShow" class="vue-modal__button-panel">
        <span
          v-for="(button, i) in buttons"
          :key="i"
          style="margin: 0.4rem 0.2rem"
        >
          <button
            v-if="button.show"
            :class="button.class"
            :disabled="button.disabled"
            @click="button.func($event)"
          >
            {{ button.name }}
          </button>
        </span>
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import Detail from "./attendance/Detail";
import Sidebar from "./generalComponents/Sidebar";
import Description from "./generalComponents/Description";
import PopUp from "./generalComponents/PopUp";
import History from "./generalComponents/History";
import { attendanceQuery } from "../graphql/attendace";
import attendanceLocales from "../graphql/locales/attendance";
import actionSubordinates from "../store/actionHelpers";
import attendanceSettings from "../graphql/attendanceSettings";
import { attendanceOverviewQuery } from "../graphql/attendanciesOverview";
import mutation from "../graphql/mutations/attendance";

export default {
  name: "AttendanceModal",
  components: { ModalWrapper, Detail, Sidebar, Description, PopUp, History },
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
      custom: {},
      allignement: {},
      currentComponent: "",
      popUpOptions: {},
      action: {},
      locales: this.$store.state.allLocales,
      block: this.$props.bemBlock,
      actions: this.$props.actionButtons
    };
  },
  computed: {
    attendance() {
      return this.$store.state.easyAttendance;
    },
    translations() {
      return this.$store.state.allLocales;
    },
    textile() {
      if (!this.$store.state.allSettings) return false;
      return this.$store.state.allSettings.text_formatting !== "HTML";
    },
    easyAttendanciesList() {
      return this.$store.state.easyAttendancesApproval.easyAttendances;
    },
    approveRejectShow() {
      const showStatuses = ["1", "4", "5", "6"];
      // If attendane isnt rejected or approved show buttons
      if (!this.attendance.approvalStatus) {
        return this.attendance.canApprove;
      }
      const show = showStatuses.find(
        (el) => el === this.attendance.approvalStatus.key
      );
      return this.attendance.canApprove && show;
    },
    buttonsShow() {
      return !!this.buttons.find((btn) => btn.show);
    },
    withButtonPanel() {
      if (this.buttonsShow) {
        return "with-buttons-panel";
      }
      return "";
    },
    sidebarButtons() {
      return [
        {
          name: this.translations.easy_attendance_attendance_overview,
          anchor: "",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick: () => {
            this.showAttendanceOverview();
          }
        },
        {
          name: this.translations.button_delete,
          anchor: "",
          active: true,
          isModuleActive: this.attendance.canDelete,
          showAddAction: false,
          onClick: (e) => {
            this.deleteAttendance(this.attendance.id);
            this.showConfirm(e, this.$props.isMobile);
          }
        }
      ];
    },
    buttons() {
      return [
        {
          name: this.translations.easy_attendance_approval_actions_2,
          func: () => {
            this.attendanceApproved("1");
            this.$refs.wrapper.closeModal();
          },
          show: this.approveRejectShow,
          class: "button-positive",
          disabled: false
        },
        {
          name: this.translations.easy_attendance_approval_actions_3,
          func: () => {
            this.attendanceApproved("0");
            this.$refs.wrapper.closeModal();
          },
          show: this.approveRejectShow,
          class: "button-negative",
          disabled: false
        }
      ];
    },
    formatedActivities() {
      const journals = this.attendance.journals;
      if (journals.length) {
        const activities = journals.map((journal) => {
          if (!journal.details.length) return;
          const activity = {
            createdOn: journal.createdOn,
            id: journal.id,
            notes: journal.notes,
            user: journal.user,
            details: {
              asString: ""
            }
          };
          journal.details.forEach((detail) => {
            activity.details.asString += `<br>${detail.asString}`;
          });
          return activity;
        });
        return activities;
      }
      return [];
    }
  },
  async created() {
    this.$set(this.$store.state, "easyAttendance", {});
    await this.openModal();
  },
  methods: {
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: attendanceLocales
        },
        processFunc(data) {
          return actionSubordinates.getLocales(data);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async openModal() {
      this.$set(this.$store.state, "easyAttendancesApproval", {});
      await this.getLocales();
      await this.fetchSettings();
      await this.fetchAttendanceData();
      this.setIsMobile();
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
    setIsMobile() {
      const options = {
        name: "isMobile",
        value: ERUI.isMobile,
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
    },
    async fetchAttendanceData() {
      // Fetch and set attendance data
      const payload = {
        name: "easyAttendance",
        apolloQuery: {
          query: attendanceQuery,
          variables: { id: this.$props.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: attendanceSettings
        },
        processFunc(array) {
          return actionSubordinates.transformArrayToObject(array);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async save(event) {
      const { name, payload } = event;
      const attributes = {
        [name]: payload.inputValue.id || payload.inputValue.key
      };
      const mutationPayload = {
        mutationName: "easyAttendanceUpdate",
        apolloMutation: {
          mutation: mutation,
          variables: {
            id: this.attendance.id,
            attributes
          }
        },
        processFunc: payload.showFlashMessage ? payload.showFlashMessage : null
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateAttendance(data);
    },
    async changeRange(event) {
      const { attributes, payload } = event;
      const mutationPayload = {
        mutationName: "easyAttendanceUpdate",
        apolloMutation: {
          mutation: mutation,
          variables: {
            id: this.attendance.id,
            attributes
          }
        },
        processFunc: payload.showFlashMessage ? payload.showFlashMessage : null
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateAttendance(data);
    },
    async saveDescription(description) {
      const attributes = {
        description
      };
      const mutationPayload = {
        mutationName: "easyAttendanceUpdate",
        apolloMutation: {
          mutation: mutation,
          variables: {
            id: this.attendance.id,
            attributes
          }
        }
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateAttendance(data);
    },
    dispatchModalChange() {
      const evt = new CustomEvent("vueModalIssueChanged", {
        cancelable: false,
        detail: {
          id: this.$props.id
        }
      });
      document.dispatchEvent(evt);
    },
    confirm(e) {
      this.action.func = e.action;
      this.action.close = e.close;
      this.showConfirm(e.eventData, this.$props.isMobile);
    },
    showConfirm(e, isMobile, options) {
      const defaultOptions = {
        topOffs: 20,
        rightOffs: 15
      };
      const alligmentOptions = options ? options : defaultOptions;
      this.custom = {
        width: "auto",
        height: "95px !important",
        display: "flex",
        "align-items": "center"
      };
      this.alignment = this.getAlignment(e, alligmentOptions, isMobile);
      this.currentComponent = "Confirm";
    },
    async showAttendanceOverview() {
      const options = {
        topOffs: 0
      };
      this.alignment = this.getAlignment(null, options, this.$props.isMobile);
      await this.fetchUserAttendances();
      this.setPopUpSettings();
    },
    async confirmAction(confirmed) {
      if (confirmed) {
        await this.action.func();
        if (this.action.close) this.$refs.wrapper.closeModal();
      }
      this.currentComponent = null;
    },
    closePopUp() {
      this.currentComponent = null;
    },
    setPopUpSettings() {
      const list = [...this.easyAttendanciesList];
      list.forEach((task) => {
        this.$set(task, "checked", false);
      });
      this.popUpOptions = {
        attendanceList: list,
        rowInputType: "checkbox",
        showRowInput: true,
        showToggleAll: true,
        data: {
          settings: {
            heading: "Pending Attendancies",
            action: "addToCheckedList",
            textile: this.textile
          }
        }
      };
      this.custom = {
        height: "700px",
        "max-width": "1200px"
      };
      this.currentComponent = "AttendanceOverview";
    },
    updateAttendance(data) {
      const { easyAttendance, errors } = data.easyAttendanceUpdate;
      if (errors) return;
      const options = {
        value: easyAttendance,
        name: "easyAttendance",
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
    },
    async fetchUserAttendances() {
      const payload = {
        name: "easyAttendancesApproval",
        apolloQuery: {
          query: attendanceOverviewQuery,
          variables: { userIds: [this.attendance.user.id] }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    deleteAttendance(id) {
      this.action.func = async () => {
        const req = new Request(`/easy_attendances/${id}.json`);
        const options = {
          method: "DELETE"
        };
        try {
          await fetch(req, options);
        } catch (err) {
          throw new Error(`Delete attendance error: ${err}`);
        }
      };
      this.action.close = true;
    }
  }
};
</script>

<style scoped></style>
