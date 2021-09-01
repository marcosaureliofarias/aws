<template>
  <section id="detail" :class="bem.ify(bem.block, 'section')">
    <ul :class="bem.ify(bem.block, 'attributes')">
      <Attribute
        :id="id"
        :bem="bem"
        :data="startTime"
        @child-value-change="saveRange(['start_time', 'end_time'], $event)"
      />
      <Attribute :id="id" :bem="bem" :data="author" />
      <Attribute
        :id="id"
        :bem="bem"
        :data="allDay"
        @child-value-change="handleAllDay"
      />
      <div class="vue-modal__attribute meeting-attribute">
        <Attribute
          :id="id"
          :class="placeClass"
          :bem="bem"
          :data="place"
          @child-value-change="saveValue('place_name', $event)"
        />
        <div class="meeting-attribute-with-button__button-wrapper">
          <a
            v-if="isEasyZoomAndZoomValue"
            :href="easyMeeting.placeName"
            target="_blank"
            class="button"
          >
            Join meeting
          </a>
        </div>
      </div>
      <div class="vue-modal__attribute meeting-attribute">
        <Attribute
          :id="id"
          class="meeting-attribute-with-button--input"
          :bem="bem"
          :data="room"
          @child-value-change="saveValue('easy_room_id', $event, true)"
        />
        <div class="meeting-attribute-with-button__button-wrapper">
          <a
            :href="meetingAvailabilityPath"
            target="_blank"
            class="button"
            :title="translations.button_check_availability"
          >
            {{ translations.button_check_availability }}
          </a>
        </div>
      </div>
      <Attribute
        :id="id"
        :bem="bem"
        :data="project"
        @child-value-change="saveValue('project_id', $event)"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="priority"
        @child-value-change="saveValue('priority', $event)"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="privacy"
        @child-value-change="saveValue('privacy', $event)"
      />
      <li v-if="showRepeating" class="vue-modal__attribute">
        <label :class="`${bem.ify(bem.block, `${bem.modifier}-label`)}`">
          {{ translations.label_easy_attendance_is_repeating }}
        </label>
        <span :class="inputWithPopupClass">
          <div v-if="!easyMeeting.easyRepeatParent" class="bool__wrapper">
            <label class="bool__label--checkbox">
              <input
                v-model="repeat"
                class="excluded"
                type="checkbox"
                @click.prevent="handlePopup('repeating', $event)"
              />
            </label>
          </div>
          <div v-else class="l__w--full" @click="handleOpenParent">
            <a href="#">{{ translations.button_open_parent }}</a>
          </div>
        </span>
      </li>
      <Attribute
        :id="id"
        :bem="bem"
        :data="mails"
        @child-value-change="saveValue('mails', $event)"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="emailNotifications"
        @child-value-change="saveValue('email_notifications', $event)"
      />
      <Attribute
        v-if="easyMeeting.easyZoomEnabled"
        :id="id"
        :bem="bem"
        :data="meetingType"
        @child-value-change="saveValue('meeting_type', $event)"
      />
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import allProjectsQuery from "../../graphql/allProjects";

export default {
  name: "Detail",
  components: { Attribute },
  props: {
    id: [Number, String],
    easyMeeting: Object,
    bem: Object,
    editOnlyParent: Boolean,
    translations: Object
  },
  data() {
    return {
      showPopup: false,
      meetingAvailabilityPath: `${window.urlPrefix}/easy_rooms/availability`
    };
  },
  computed: {
    editable() {
      return !this.editOnlyParent && this.easyMeeting.editable;
    },
    showRepeating() {
      const repeatParent = this.easyMeeting.easyRepeatParent;
      if (!repeatParent) return true;
      return repeatParent.visible;
    },
    placeEditable() {
      const meeting = this.easyMeeting;
      if (!meeting.easyZoomEnabled || !meeting.meetingType)
        return this.editable;
      const zoomValue =
        meeting.meetingType.key === "video" ||
        meeting.meetingType.key === "audio";
      return this.editable && !zoomValue;
    },
    placeWithLink() {
      const meeting = this.easyMeeting;
      if (!meeting.easyZoomEnabled || !meeting.meetingType) return false;
      const zoomValue =
        meeting.meetingType.key === "video" ||
        meeting.meetingType.key === "audio";
      return zoomValue;
    },
    startTime() {
      const type = this.easyMeeting.allDay ? "date" : "datetime";
      return {
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName: "start -> end",
        date: this.date,
        inputType: type,
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: this.editable,
        range: true,
        onClick: this.handleAttributeClick
      };
    },
    place() {
      return {
        labelName: this.translations.field_place_name,
        value: this.easyMeeting.placeName,
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.placeEditable,
        withLink: this.placeWithLink,
        link: this.easyMeeting.placeName,
        onClick: this.handleAttributeClick
      };
    },
    mails() {
      return {
        labelName: this.translations.field_mails,
        value: this.easyMeeting.mails,
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.editable,
        onClick: this.handleAttributeClick
      };
    },
    repeat() {
      return this.easyMeeting.easyIsRepeating;
    },
    allDay() {
      return {
        labelName: this.translations.field_all_day,
        value: this.editable
          ? this.easyMeeting.allDay
          : this.textilizeBool(this.easyMeeting.allDay),
        inputType: "bool",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: this.editable,
        tagStyle: "check_box",
        onClick: this.handleAttributeClick
      };
    },
    author() {
      return {
        labelName: this.translations.field_author,
        value: this.easyMeeting.author.name,
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false,
        onClick: this.handleAttributeClick
      };
    },
    room() {
      return {
        labelName: this.translations.field_easy_room,
        value: this.easyMeeting.easyRoom ? this.easyMeeting.easyRoom.name : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        filterable: false,
        searchQuery: this.fetchRooms,
        withSpan: false,
        editable: this.editable,
        onClick: this.handleAttributeClick
      };
    },
    project() {
      return {
        labelName: this.translations.label_project,
        value: this.easyMeeting.project ? this.easyMeeting.project.name : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        filterable: false,
        firstOptionEmpty: true,
        searchQuery: this.fetchProjects,
        withSpan: false,
        editable: this.editable,
        onClick: this.handleAttributeClick
      };
    },
    priority() {
      return {
        labelName: this.translations.field_priority,
        value: this.easyMeeting.priority ? this.easyMeeting.priority.value : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: this.humanizeHashKeyValue(
          this.easyMeeting.availablePriorities
        ),
        filterable: true,
        withSpan: false,
        editable: this.editable,
        onClick: this.handleAttributeClick
      };
    },
    privacy() {
      return {
        labelName: this.translations.field_privacy,
        value: this.easyMeeting.privacy ? this.easyMeeting.privacy.value : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: this.humanizeHashKeyValue(
          this.easyMeeting.availablePrivacies
        ),
        filterable: true,
        withSpan: false,
        editable: this.editable,
        onClick: this.handleAttributeClick
      };
    },
    emailNotifications() {
      return {
        labelName: this.translations.label_meeting_email_settings,
        value: this.emailNotificationsValue,
        inputType: "bool",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: this.editable,
        tagStyle: "radio",
        radioButtons: this.humanizeHashKeyValue(
          this.easyMeeting.availableEmailNotifications
        ),
        onClick: this.handleAttributeClick
      };
    },
    meetingType() {
      return {
        labelName: "meeting type",
        value: this.easyMeeting.meetingType
          ? this.easyMeeting.meetingType.key
          : "",
        inputType: "bool",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: this.editable,
        tagStyle: "radio",
        radioButtons: this.humanizeHashKeyValue(
          this.easyMeeting.availableMeetingTypes
        ),
        onClick: this.handleAttributeClick
      };
    },
    emailNotificationsValue() {
      const notifications = this.easyMeeting.emailNotifications;
      if (!notifications) return "";
      return notifications && this.editable
        ? notifications.key
        : notifications.value;
    },
    isEasyZoomAndZoomValue() {
      if (!this.easyMeeting) return false;
      let easyZoomValue = false;
      const isEasyZoom = this.easyMeeting.easyZoomEnabled;
      const meetingType = this.easyMeeting.meetingType;
      if (meetingType) {
        easyZoomValue =
          meetingType.key === "video" || meetingType.key === "audio";
      }
      return isEasyZoom && easyZoomValue;
    },
    placeClass() {
      return {
        "meeting-attribute-with-button--input": true,
        "meeting-attribute-with-button--input-full": !this
          .isEasyZoomAndZoomValue
      };
    },
    date() {
      const { startTime, endTime } = this.easyMeeting;
      return [startTime, endTime];
    },
    inputWithPopupClass() {
      return {
        "editable-input__wrapper": true,
        " editable-input__wrapper--static": true,
        excluded: true,
        "no-hover": !this.editable
      };
    }
  },
  methods: {
    async handlePopup(component, e) {
      if (!this.editable) return;
      this.$emit("handle-popup", { component, e });
    },
    handleAllDay(payload) {
      this.saveValue("all_day", payload, true);
      const options = {
        name: "allDay",
        value: payload.inputValue,
        level: "easyMeeting"
      };
      this.$store.commit("setStoreValue", options);
    },
    async fetchRooms(id, term) {
      const params = {
        easy_meeting_id: id,
        end_time: this.date[1],
        start_time: this.date[0],
        term: term || ""
      };
      const builtParams = Object.keys(params).reduce((acc, curr) => {
        return `${acc}&${curr}=${params[curr]}`;
      }, "");
      const url = `${window.urlPrefix}/easy_autocompletes/room_availability_for_date_time?${builtParams}`;
      const request = await fetch(url);
      const data = await request.json();
      const transformedData = data.map(({ value, id, available }) => {
        return {
          value,
          id,
          disabled: !available
        };
      });
      return transformedData;
    },
    async fetchProjects(id, term) {
      const payload = {
        name: "allProjects",
        level: "easyMeeting",
        apolloQuery: {
          query: allProjectsQuery,
          variables: {
            filter: {
              name: {
                match: term
              }
            }
          }
        }
      };
      const response = await this.$store.dispatch("fetchStateValue", payload);
      return response.data.allProjects;
    },
    saveValue(name, payload, withResetInvitations) {
      const emitType = withResetInvitations
        ? "open-reset-invitations"
        : "save-value";
      const inputValue = payload.inputValue.id
        ? payload.inputValue.id
        : payload.inputValue;
      this.$emit(emitType, {
        payload: { [name]: inputValue },
        showFlashMessage: payload.showFlashMessage
      });
    },
    saveRange(keys, payload) {
      const data = {};
      keys.forEach((key, index) => {
        data[key] = payload.inputValue[index];
      });
      this.$emit("open-reset-invitations", {
        payload: data,
        showFlashMessage: payload.showFlashMessage
      });
    },
    handleAttributeClick() {
      if (!this.editOnlyParent) return;
      this.$emit("edit-only-parent");
    },
    handleOpenParent() {
      const easyMeetingParent = this.easyMeeting.easyRepeatParent;
      if (!easyMeetingParent.visible) return;
      this.$emit("open-new-modal", easyMeetingParent.id);
    }
  }
};
</script>

<style scoped></style>
