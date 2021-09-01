<template>
  <div>
    <div class="vue-modal__form-step">
      <Attribute
        ref="subjectInput"
        class="vue-modal__attribute--long"
        :data="nameInput"
        :bem="bem"
        :lazy="true"
        :required="true"
        @child-value-input="setValue('name', $event)"
      />
    </div>
    <transition name="slide-fade">
      <div v-if="newMeeting.name">
        <div class="vue-modal__form-step">
          <Attribute
            class="vue-modal__attribute--long"
            :bem="bem"
            :data="startEnd"
            :required="true"
            @child-value-change="setRangeValue"
          />
          <Attribute
            style="flex-basis: 10%"
            :bem="bem"
            :data="allDay"
            @child-value-change="setValue('all_day', $event)"
          />
        </div>
        <div class="vue-modal__form-step">
          <Attribute
            class="vue-modal__attribute--long"
            :bem="bem"
            :data="privacy"
            @child-value-change="setPrivacy"
          />
        </div>
        <div class="vue-modal__form-step">
          <li class="vue-modal__attribute">
            <label :class="`${bem.ify(bem.block, `${bem.modifier}-label`)}`">
              {{ translations.label_easy_attendance_is_repeating }}
            </label>
            <span
              class="editable-input__wrapper editable-input__wrapper--static"
            >
              <div class="bool__wrapper">
                <label class="bool__label--checkbox">
                  <input
                    v-model="newMeeting.easy_is_repeating"
                    class="excluded"
                    type="checkbox"
                    @click.prevent="
                      $emit('open-popup', { component: 'Repeating' })
                    "
                  />
                </label>
              </div>
            </span>
          </li>
        </div>
        <div class="vue-modal__form-step">
          <Attribute
            class="vue-modal__attribute--long"
            :bem="bem"
            :data="emailNotifications"
            @child-value-change="setValue('email_notifications', $event)"
          />
        </div>
        <div class="vue-modal__form-step meeting-room">
          <Attribute
            :id="id"
            class="meeting-attribute-with-button--input"
            :bem="bem"
            :data="room"
            @child-value-change="setRooms"
          />
          <a
            :href="meetingAvailabilityPath"
            target="_blank"
            class="button"
            :title="translations.button_check_availability"
          >
            {{ translations.button_check_availability }}
          </a>
        </div>
        <div v-if="newMeeting.easyZoomEnabled" class="vue-modal__form-step">
          <Attribute
            class="vue-modal__attribute--long"
            :bem="bem"
            :data="meetingType"
            @child-value-change="setMeetingType"
          />
        </div>
        <div class="vue-modal__form-step">
          <Attribute
            class="vue-modal__attribute--long"
            :bem="bem"
            :data="invitations"
            :required="true"
            :multiple="true"
            @child-value-change="setInvitations"
          />
        </div>
        <div class="vue-modal__form-step">
          <Attribute
            class="vue-modal__attribute--long"
            :bem="bem"
            :data="mails"
            :lazy="true"
            @child-value-input="setValue('mails', $event)"
          />
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import Attribute from "../generalComponents/Attribute";

export default {
  name: "Body",
  components: { Attribute },
  props: {
    block: {
      type: String,
      default: () => ""
    },
    id: {
      type: [String, Number],
      required: true
    },
    translations: {
      type: Object,
      default: () => {}
    },
    bem: {
      type: Object,
      required: true
    },
    newMeeting: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      meetingAvailabilityPath: `${window.urlPrefix}/easy_rooms/availability`
    };
  },
  computed: {
    nameInput() {
      return {
        labelName: "subject",
        classes: {
          edit: ["u-editing"],
          show: ["u-showing editable-input__wrapper--subject"]
        },
        placeholder: "",
        value: this.newMeeting.name,
        inputType: "text",
        withSpan: false,
        editable: true,
        optionsArray: false,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    startEnd() {
      const type = this.newMeeting.all_day ? "date" : "datetime";
      return {
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName: "start -> end",
        date: [this.newMeeting.start_time, this.newMeeting.end_time],
        inputType: type,
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: true,
        range: true,
        withLoading: false,
        customLabels: {
          datepickerConfirmLabel: this.translations.button_confirm
        }
      };
    },
    allDay() {
      return {
        labelName: this.translations.field_all_day,
        value: this.newMeeting.all_day,
        inputType: "bool",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: true,
        tagStyle: "check_box",
        withLoading: false
      };
    },
    invitations() {
      return {
        labelName: this.translations.label_invitations,
        value: this.newMeeting.easyInvitations,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        searchQuery: this.fetchUsers,
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    mails() {
      return {
        labelName: this.translations.field_mails,
        classes: {
          edit: ["u-editing"],
          show: ["u-showing editable-input__wrapper--subject"]
        },
        placeholder: "",
        value: this.newMeeting.mails,
        inputType: "text",
        withSpan: false,
        editable: true,
        optionsArray: false,
        errors: "",
        errorType: null,
        withLoading: false
      };
    },
    emailNotifications() {
      return {
        labelName: this.translations.label_meeting_email_settings,
        value: this.newMeeting.email_notifications,
        inputType: "bool",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: true,
        tagStyle: "radio",
        radioButtons: [
          { id: "right_now", name: "now" },
          { id: "one_week_before", name: "7 days before" }
        ],
        withLoading: false
      };
    },
    room() {
      return {
        labelName: this.translations.field_easy_room,
        value: this.newMeeting.easyRoomId,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        filterable: false,
        searchQuery: this.fetchRooms,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    meetingType() {
      return {
        labelName: "meeting type",
        value: this.newMeeting.meetingType
          ? this.newMeeting.meetingType.key
          : "",
        inputType: "bool",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: true,
        tagStyle: "radio",
        radioButtons: this.humanizeHashKeyValue(
          this.newMeeting.availableMeetingTypes
        ),
        withLoading: false
      };
    },
    privacy() {
      return {
        labelName: this.translations.field_privacy,
        value: this.newMeeting.privacyHelper,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: this.humanizeHashKeyValue(
          this.newMeeting.availablePrivacies
        ),
        filterable: true,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    }
  },
  mounted() {
    this.$refs.subjectInput.focusAttribute();
  },
  methods: {
    async fetchUsers(id, term) {
      term = term || "";
      const url = `/easy_autocompletes/users_in_meeting_calendar?include_groups=true&include_me=true&term=${term}`;
      const response = await fetch(url);
      const data = await response.json();
      const formattedData = [];
      data.users.forEach(user => {
        const value = user.id === "me" ? EASY.currentUser.id : user.id;
        formattedData.push({
          value: value,
          name: user.value
        });
      });
      return formattedData;
    },
    setValue(name, { inputValue }) {
      this.$emit("set-value", { name, inputValue });
    },
    setRangeValue(payload) {
      const { inputValue: input } = payload;
      this.setValue("start_time", { inputValue: input[0] });
      this.setValue("end_time", { inputValue: input[1] });
    },
    setInvitations({ inputValue: invitations }) {
      const userIds = invitations.map(invitation => invitation.value);
      this.setValue("user_ids", { inputValue: userIds });
      this.setValue("easyInvitations", { inputValue: invitations });
    },
    setPrivacy({ inputValue: privacy }) {
      this.setValue("privacyHelper", { inputValue: privacy });
      this.setValue("privacy", { inputValue: privacy.id });
    },
    setRooms({ inputValue: meetingRoom }) {
      this.setValue("easy_room_id", { inputValue: meetingRoom.id });
      this.setValue("easyRoomId", { inputValue: meetingRoom });
    },
    setMeetingType({ inputValue: meetingType }) {
      this.setValue("meeting_type", { inputValue: meetingType });
      this.setValue("meetingType", { inputValue: meetingType });
    },
    async fetchRooms(id, term) {
      const params = {
        easy_meeting_id: id,
        end_time: this.startEnd.date[1],
        start_time: this.startEnd.date[0],
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
    }
  }
};
</script>

<style scoped></style>
