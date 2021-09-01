<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    :id="meeting.id"
    ref="modal-wrapper"
    modificator="meeting"
    entity-type="meeting"
    :block="block"
    :previous-path-name="previousPathName"
    :previous-search="previousSearch"
    :on-close-fnc="dispatchModalChange"
  >
    <template slot="headline">
      <h2 :class="`${bemBlock}__headline`">
        <InlineInput
          :id="meeting.id"
          :data="subjectInput"
          :value="meeting.name"
          @child-value-change="saveSubject"
        />
      </h2>
    </template>
    <template slot="body">
      <Detail
        :id="meeting.id"
        :easy-meeting="meeting"
        :bem="bem"
        :translations="translations"
        :edit-only-parent="editOnlyParent"
        @save-value="saveValues"
        @edit-only-parent="showEditOnlyParentModal"
        @handle-popup="handlePopup"
        @open-new-modal="openNewModal"
        @open-reset-invitations="showResendPopup"
      />
      <Description
        :bem="bem"
        :editable="!editOnlyParent && meeting.editable"
        :textile="textile"
        :entity="meeting"
        @save="saveDescription"
      />
      <Invitations
        :invitations="meeting.easyInvitations"
        :editable="!editOnlyParent && meeting.editable"
        :translations="translations"
        :bem="bem"
        @handle-popup="handlePopup"
      />
      <Mails
        v-if="meeting.mails"
        :mails="meeting.mails"
        :translations="translations"
        :bem="bem"
      />
      <section v-if="showProject" :class="bem.ify(block, 'section')">
        <h2 :class="bem.ify(block, 'heading') + ' icon--projects'">
          {{ translations.label_project }}
        </h2>
        <div>
          <div>{{ meeting.project.name }}</div>
          <div v-html="meeting.project.description" />
        </div>
      </section>
      <PopUp
        v-if="showPopup"
        class="vue-modal__popup--repeating"
        :bem="bem"
        :component="popupComponent"
        :translations="translations"
        :custom-styles="customPopupStyles"
        :entity="meeting"
        :align="alignment"
        @onBlur="onPopupBlur"
        @data-change="saveValues"
      />
    </template>
    <Sidebar
      slot="sidebar"
      :actions="actionButtons"
      :reference="`${id}`"
      :bem="bem"
      :custom-url="customUrl"
      @close="$refs['modal-wrapper'].closeModal()"
    />
    <template v-if="isCurrentUserInvited" slot="button-panel">
      <div class="vue-modal__button-panel">
        <button
          v-for="(button, i) in bottomButtons"
          :key="i"
          :class="button.class"
          :disabled="button.disabled"
          @click="button.func()"
        >
          {{ button.name }}
        </button>
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import Sidebar from "./generalComponents/Sidebar";
import actionHelpers from "../store/actionHelpers";
import { meetingQuery } from "../graphql/meeting";
import meetingLocales from "../graphql/locales/meeting";
import Detail from "./meeting/Detail";
import InlineInput from "./generalComponents/InlineInput";
import PopUp from "./generalComponents/PopUp";
import DeleteRepeating from "./meeting/DeleteRepeating";
import OnlyParentMessage from "./meeting/OnlyParentMessage";
import ResendInvitations from "./meeting/ResendInvitations";

import issueHelper from "../store/actionHelpers";
import meetingSettings from "../graphql/meetingSettings";
import Description from "./generalComponents/Description";
import Invitations from "./meeting/Invitations";
import Mails from "./meeting/Mails";
import meeting from "../graphql/mutations/meeting";
import { zoomQuery } from "../graphql/zoomData";
import allUsersQuery from "../graphql/allUsers";

export default {
  name: "MeetingModal",
  components: {
    Mails,
    Invitations,
    Description,
    Detail,
    Sidebar,
    ModalWrapper,
    InlineInput,
    PopUp
  },
  props: {
    id: [String, Number],
    options: {
      type: Object,
      default() {
        return {};
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
      previousSearch: "",
      block: this.$props.bemBlock,
      customPopupStyles: null,
      alignment: null,
      popupComponent: "",
      showPopup: false,
      datePayloadHelper: null
    };
  },
  computed: {
    meeting() {
      return this.$store.state.easyMeeting;
    },
    translations() {
      return this.$store.state.allLocales;
    },
    editOnlyParent() {
      if (!this.meeting) return false;
      return !!this.meeting.easyRepeatParent && this.meeting.bigRecurring;
    },
    customUrl() {
      return `${window.urlPrefix}/easy_meetings/${this.meeting.id}`;
    },
    bottomButtons() {
      const invitations = this.meeting.easyInvitations;
      // If user has accepted invitation, we can disable accept button
      const isAccepted = invitations.some(invitation => {
        const invitationUser = parseInt(invitation.user.id);
        const currentUser = EASY.currentUser.id;
        return invitationUser === currentUser && invitation.accepted;
      });
      return [
        {
          name: this.translations.button_meeting_accept,
          func: () => {
            fetch(`${window.urlPrefix}/easy_meetings/${this.id}/accept.json`, {
              method: "POST",
              headers: { "Content-Type": "application/json" }
            });
            const wrapper = this.$refs["modal-wrapper"];
            wrapper.closeModal();
          },
          class: "button-positive",
          disabled: isAccepted
        },
        {
          name: this.translations.button_meeting_decline,
          func: () => {
            fetch(`${window.urlPrefix}/easy_meetings/${this.id}/decline.json`, {
              method: "POST",
              headers: { "Content-Type": "application/json" }
            });
            const wrapper = this.$refs["modal-wrapper"];
            wrapper.closeModal();
          },
          class: "button-negative",
          disabled: false
        },
        {
          name: this.translations.button_cancel,
          func: () => {
            const wrapper = this.$refs["modal-wrapper"];
            wrapper.closeModal();
          },
          class: "button",
          disabled: false
        }
      ];
    },
    actionButtons() {
      const options = this.options.actions || [];
      const meetingDefaultButtons = [
        {
          name: this.translations.button_delete,
          func: (params, ctx, e) => {
            if (this.editOnlyParent) {
              this.showEditOnlyParentModal();
              return;
            }
            this.handlePopup({ component: DeleteRepeating, e });
            this.setPopupStyles({
              ...this.customPopupStyles,
              ...{
                "min-height": `auto`,
                "max-width": "auto",
                "max-height": "200px"
              }
            });
          },
          disabled: !this.meeting.editable
        },
        {
          name: this.translations.button_log_time,
          func: () => {
            return;
          },
          href: this.logTimeUrl,
          disabled: false
        }
      ];
      return [...options, ...meetingDefaultButtons];
    },
    logTimeUrl() {
      if (!this.meeting) return "";
      const project = this.meeting.project;
      const baseUrl = `${window.urlPrefix}/easy_time_entries/new`;
      const baseParams =
        "?modal=true&amp;utm_campaign=menu&amp;utm_content=easy_new_entity&amp;utm_term=log_time_new";
      const startDate = moment(this.meeting.startTime);
      const endDate = moment(this.meeting.endTime);
      const minutes = endDate.diff(startDate, "minutes");
      const hoursParam = `&time_entry[hours]=${minutes / 60}`;
      const dateParam = `&time_entry[spent_on]=${this.meeting.startTime}`;
      const projectParam = project
        ? `&time_entry[project_id]=${project.id}`
        : "";
      return `${baseUrl}${baseParams}${hoursParam}${dateParam}${projectParam}`;
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
        editable: !this.editOnlyParent && this.meeting.editable
      };
    },
    showProject() {
      const project = this.meeting.project;
      return project && project.id;
    },
    isCurrentUserInvited() {
      const meeting = this.meeting;
      if (
        !meeting ||
        !meeting.easyInvitations ||
        !meeting.easyInvitations.length
      )
        return false;
      const currentUser = EASY.currentUser;
      const invitations = meeting.easyInvitations;
      const currentUserInvited = invitations.some(
        invitation => +invitation.user.id === +currentUser.id
      );
      return currentUserInvited;
    },
    textile() {
      if (!this.$store.state.allSettings) return false;
      return this.$store.state.allSettings.text_formatting !== "HTML";
    }
  },
  created() {
    this.$set(this.$store.state, "easyMeeting", {});
    this.openModal();
  },
  methods: {
    async openModal() {
      await this.getLocales();
      await this.fetchSettings();
      await this.fetchMeetingData();
      await this.fetchAllUsers();
      await this.fetchZoomData();
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state"
      };
      this.$store.commit("setStoreValue", payloadShow);
    },
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: meetingLocales
        },
        processFunc(data) {
          return actionHelpers.getLocales(data);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchMeetingData() {
      // Fetch and set meeting data
      const payload = {
        name: "easyMeeting",
        apolloQuery: {
          query: meetingQuery,
          variables: { id: this.$props.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchAllUsers() {
      const payload = {
        name: "allUsers",
        apolloQuery: {
          query: allUsersQuery
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchZoomData() {
      if (!this.meeting.easyZoomEnabled) return;
      const meeting = { ...this.meeting };
      const payload = {
        name: "easyMeeting",
        apolloQuery: {
          query: zoomQuery,
          variables: { id: this.$props.id }
        }
      };
      const result = await this.$store.dispatch("fetchStateValue", payload);
      const resultPayload = {
        name: "easyMeeting",
        value: { ...meeting, ...result.data.easyMeeting },
        level: "state"
      };
      await this.$store.commit("setStoreValue", resultPayload);
    },
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: meetingSettings
        },
        processFunc(array) {
          return issueHelper.transformArrayToObject(array);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
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
    async saveValues(data) {
      const mutationPayload = {
        mutationName: "easyMeetingUpdate",
        apolloMutation: {
          mutation: meeting(this.meeting.easyZoomEnabled),
          variables: {
            id: this.meeting.id,
            attributes: data.payload
          }
        },
        processFunc: data.showFlashMessage ? data.showFlashMessage : null
      };
      const response = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      const {
        data: {
          easyMeetingUpdate: { errors, easyMeeting }
        }
      } = response;
      if (errors.length) return;
      const options = {
        name: "easyMeeting",
        value: easyMeeting,
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
    },
    saveSubject(payload) {
      this.saveValues({
        payload: { name: payload.inputValue },
        showFlashMessage: payload.showFlashMessage
      });
    },
    saveDescription(value) {
      this.saveValues({
        payload: { description: value }
      });
    },
    async handlePopup({ component }) {
      this.setPopupStyles({
        position: "fixed !important",
        "min-height": `400px`,
        "max-width": "600px",
        left: " 50% !important",
        top: "50% !important",
        transform: "translate(-50%, -50%) !important",
        display: "flex"
      });
      this.popupComponent = component;
      this.showPopup = true;
    },
    setPopupStyles(styles) {
      this.customPopupStyles = styles;
    },
    async openNewModal(id) {
      const wrapper = this.$refs["modal-wrapper"];
      wrapper.closeModal();
      await this.$nextTick();
      EasyVue.showModal("meeting", id);
    },
    onPopupBlur(payload) {
      if (payload && payload.func) {
        payload.func(this);
      }
      this.datePayloadHelper && this.saveRange(payload);
      this.showPopup = false;
    },
    showResendPopup(payload) {
      this.datePayloadHelper = payload;
      this.setPopupStyles({
        position: "fixed !important",
        height: `150px !important`,
        "max-width": "300px",
        left: " 50%",
        top: "50%",
        transform: "translate(-50%, -50%) !important",
        display: "flex"
      });
      this.popupComponent = ResendInvitations;
      this.showPopup = true;
    },
    saveRange(resendInvitations) {
      const data = this.datePayloadHelper;
      data.payload["reset_notifications"] = !!resendInvitations;
      this.saveValues(data);
      this.datePayloadHelper = null;
    },
    showEditOnlyParentModal() {
      this.setPopupStyles({
        position: "fixed !important",
        "min-height": `auto`,
        "max-height": "150px",
        "max-width": "auto",
        left: " 50% !important",
        top: "50% !important",
        transform: "translate(-50%, -50%) !important",
        display: "flex"
      });
      this.popupComponent = OnlyParentMessage;
      this.showPopup = true;
    }
  }
};
</script>

<style scoped></style>
