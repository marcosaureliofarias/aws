<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="modal-wrapper"
    :class="`${bemBlock}--no-sidebar`"
    :block="bemBlock"
    modificator="new meeting"
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
    <template slot="body">
      <Body
        :id="id"
        :block="bemBlock"
        :bem="bem"
        :new-meeting="newMeeting"
        :translations="translations"
        @open-popup="handlePopup"
        @set-value="setValue"
      />
      <PopUp
        v-if="showPopup"
        class="vue-modal__popup--repeating"
        :bem="bem"
        :component="popupComponent"
        :translations="translations"
        :custom-styles="customPopupStyles"
        :entity="newMeeting"
        :align="alignment"
        @data-change="setChanges"
        @onBlur="onPopupBlur"
      />
      <Notification
        v-show="showErrors"
        :bem="bem"
        type="error"
        class="vue-modal__notification--beforeSubmit"
      >
        <ul>
          <li v-for="(error, i) in errors" :key="i">
            {{ error }}
          </li>
        </ul>
      </Notification>
    </template>
    <template slot="button-panel">
      <div class="vue-modal__button-panel">
        <button
          :class="disableCreation ? 'button disabled' : 'button-positive'"
          @click="createMeeting"
          @mouseenter="onCreateButtonMouseIn"
          @mouseleave="onCreateButtonMouseOut"
        >
          Create
        </button>
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import locales from "../graphql/locales/meeting";
import Body from "../components/newMeeting/Body";
import PopUp from "./generalComponents/PopUp";
import Notification from "./generalComponents/Notification";
import NewEntitySelect from "./NewEntitySelect";

import issueHelper from "../store/actionHelpers";
import { allSettingsQueryWithoutProject } from "../graphql/allSettings";
import { meetingValidator } from "../graphql/mutations/meetingValidator";
import { meetingPluginsValidator } from "../graphql/mutations/meetingPluginsValidator";

export default {
  name: "NewMeetingModal",
  components: { ModalWrapper, Body, PopUp, Notification, NewEntitySelect },
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
    options: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      id: "new_meeting",
      customPopupStyles: null,
      alignment: null,
      popupComponent: "",
      showPopup: false,
      bem: {
        block: this.$props.bemBlock,
        ify: function(b, e, m) {
          let output = b;
          output += e ? "__" + e : "";
          output = m ? output + " " + output + "--" + m : output;
          return output.toLowerCase();
        }
      },
      disableCreation: true,
      errors: [],
      showErrors: false
    };
  },
  computed: {
    newMeeting() {
      return this.$store.state.newMeeting;
    },
    translations() {
      return this.$store.state.allLocales;
    }
  },
  created() {
    this.init();
  },
  methods: {
    async init() {
      const store = this.$store;
      this.$set(this.$store.state, "newMeeting", {});
      this.setInitialState(store);
      await this.validateSchema(store);
      await this.getLocales(store);
      await this.fetchSettings();
      await this.fetchFields();
      this.setStaticFields();
      await this.fetchZoom();

      this.$store.state.showModal = true;
      document.body.classList.add("vueModalOpened");
    },
    getCurrentUser() {
      const user = window.EASY && window.EASY.currentUser;
      if (!user) return;
      return { value: user.id, name: `${user.firstName} ${user.lastName}` };
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
    async handlePopup({ component }) {
      this.setPopupStyles({
        position: "fixed !important",
        "min-height": `400px`,
        "max-width": "600px",
        left: " 50%",
        top: "50%",
        transform: "translate(-50%, -50%) !important",
        display: "flex"
      });
      this.popupComponent = component;
      this.showPopup = true;
    },
    setPopupStyles(styles) {
      this.customPopupStyles = styles;
    },
    setChanges({ payload }) {
      const modifiedLoad = { ...payload };
      modifiedLoad["easyRepeatSettings"] = modifiedLoad.easy_repeat_settings;
      modifiedLoad["easyIsRepeating"] = modifiedLoad.easy_is_repeating;
      const merged = { ...this.newMeeting, ...modifiedLoad };
      const commitPayload = {
        name: "newMeeting",
        value: merged,
        level: "state"
      };
      this.$store.commit("setStoreValue", commitPayload);
    },
    onPopupBlur(payload) {
      if (payload && payload.func) {
        payload.func(this);
      }
      this.showPopup = false;
    },
    setValue({ name, inputValue }) {
      const payload = {
        name: name,
        value: inputValue,
        level: "newMeeting"
      };
      this.$store.commit("setStoreValue", payload);
      this.validate();
    },
    async createMeeting() {
      if (this.errors.length || this.disableCreation) return;
      const payload = {
        easy_meeting: {
          ...this.newMeeting,
          start_time: this.parseTimezone(this.newMeeting.start_time),
          end_time: this.parseTimezone(this.newMeeting.end_time)
        }
      };
      const response = await fetch(`${window.urlPrefix}/easy_meetings.json`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(payload)
      });
      const data = await response.json();
      if (data.errors && data.errors.length) return;
      this.openMeetingModal(+data.easy_meeting.id);
    },
    async validate() {
      const mutationPayload = {
        mutationName: "easyMeetingValidator",
        apolloMutation: {
          mutation: meetingValidator,
          variables: {
            attributes: {
              ...this.newMeeting,
              start_time: this.parseTimezone(this.newMeeting.start_time),
              end_time: this.parseTimezone(this.newMeeting.end_time)
            }
          }
        }
      };
      const response = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      const data = response.data.easyMeetingValidator;
      if (data.errors && data.errors.length) {
        this.disableCreation = true;
        this.errors = [...data.errors[0].fullMessages];
      } else {
        this.disableCreation = false;
        this.errors = [];
      }
    },
    async openMeetingModal(id) {
      const wrapper = this.$refs["modal-wrapper"];
      wrapper.closeModal();
      await this.$nextTick();
      EasyVue.showModal("meeting", id);
    },
    onCreateButtonMouseIn() {
      this.showErrors = this.errors && this.errors.length;
    },
    onCreateButtonMouseOut() {
      this.showErrors = false;
    },
    async fetchFields() {
      const payload = {
        mutationName: "easyMeetingValidator",
        apolloMutation: {
          mutation: meetingValidator,
          variables: {
            attributes: {}
          }
        },
        pathToGet: ["easyMeetingValidator", "easyMeeting"],
        pathToSet: ["newMeeting"]
      };
      await this.$store.dispatch("mutateValue", payload);
    },
    setStaticFields() {
      const currentUser = this.getCurrentUser();
      const optionsStart = this.options.range?.start;
      const optionsEnd = this.options.range?.end;
      const now = new Date();
      const nowPlusHour = new Date(now.getTime());
      nowPlusHour.setHours(now.getHours() + 1);

      const staticFields = {
        name: "",
        start_time: optionsStart ? new Date(optionsStart) : now,
        end_time: optionsEnd ? new Date(optionsEnd) : nowPlusHour,
        user_ids: [currentUser.value],
        all_day: false,
        mails: "",
        email_notifications: "one_week_before",
        easy_is_repeating: false,
        easyIsRepeating: false,
        big_recurring: false,
        easyInvitations: [currentUser],
        easyRepeatSettings: {},
        easyRoomId: "",
        easy_room_id: "",
        meeting_type: "meeting",
        privacyHelper: { id: "xpublic", name: "public" },
        privacy: "xpublic"
      };
      const merged = { ...this.$store.state.newMeeting, ...staticFields };
      const commitPayload = {
        name: "newMeeting",
        value: merged,
        level: "state"
      };
      this.$store.commit("setStoreValue", commitPayload);
    },
    async fetchZoom() {
      const newMeeting = this.$store.state.newMeeting;
      if (!newMeeting.easyZoomEnabled) return;
      const payload = {
        mutationName: "easyMeetingValidator",
        apolloMutation: {
          mutation: meetingPluginsValidator(true),
          variables: {
            attributes: {}
          }
        }
      };
      const result = await this.$store.dispatch("mutateValue", payload);
      const merged = {
        ...newMeeting,
        ...result.data.easyMeetingValidator.easyMeeting
      };
      const resultPayload = {
        name: "newMeeting",
        value: merged,
        level: "state"
      };
      await this.$store.commit("setStoreValue", resultPayload);
    }
  }
};
</script>

<style scoped></style>
