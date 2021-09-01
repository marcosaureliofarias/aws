<template>
  <section id="detail" :class="bem.ify(bem.block, 'section')">
    <ul :class="bem.ify(bem.block, 'attributes')">
      <Attribute
        :id="id"
        :bem="bem"
        :data="activity_list"
        @child-value-change="saveValue('easy_attendance_activity_id', $event)"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="user"
        @child-value-change="saveValue('user_id', $event)"
      />
      <Attribute
        v-if="showDateInput"
        :id="id"
        :bem="bem"
        :data="dateInput"
        @child-value-change="changeDate('date', $event)"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="startDate"
        @child-value-change="changeDate('arrival', $event)"
      />
      <Attribute
        v-if="attendance.range"
        :id="id"
        :bem="bem"
        :data="dueDate"
        @child-value-change="changeDate('departure', $event)"
      />
      <Attribute :id="id" :bem="bem" :data="atWork" />
      <Attribute
        v-if="attendance.approvalStatus"
        :id="id"
        :bem="bem"
        :data="approvalStatus"
      />
      <Attribute :id="id" :bem="bem" :data="approvedBy" />
      <Attribute :id="id" :bem="bem" :data="approvedAt" />
      <Attribute
        v-if="showPortion"
        :id="id"
        :bem="bem"
        :data="range"
        @child-value-change="saveRange('range', $event)"
      />
    </ul>
    <PopUp
      v-if="showPopup"
      class="vue-modal__popup--repeating"
      :bem="bem"
      component="Repeating"
      :translations="translations"
      :custom-styles="customPopupStyles"
      :entity="easyMeeting"
      :align="alignment"
      @onBlur="showPopup = false"
    />
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import PopUp from "../generalComponents/PopUp";

export default {
  name: "Detail",
  components: { Attribute, PopUp },
  props: {
    id: {
      type: [Number, String],
      default: () => 1
    },
    data: {
      type: Object,
      default: () => {}
    },
    bem: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      showPopup: false,
      customPopupStyles: {
        position: "fixed !important",
        height: "300px",
        "max-width": "600px"
      },
      popUpOptions: "",
      alignment: null
    };
  },
  computed: {
    attendance() {
      return this.$props.data;
    },
    showPortion() {
      const activity = this.attendance.easyAttendanceActivity;
      const range = this.attendance.range;
      if (!range || !activity || activity.id === "2") {
        return false;
      }
      return true;
    },
    showDateInput() {
      const range = this.attendance.range;
      return (range && range.key !== "3") || !range;
    },
    activity_list() {
      return {
        labelName: this.translations.field_easy_attendance_activity,
        value: {
          name: this.attendance.easyAttendanceActivity.name,
          id: this.attendance.easyAttendanceActivity.id
        },
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "easy_attendance_activity_id",
        optionsArray: this.allowedActivities,
        filterable: true,
        withSpan: false,
        editable: this.attendance.canEdit
      };
    },
    range() {
      return {
        labelName: this.translations.easy_attendance_field_range,
        value: this.attendance.range,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "range",
        optionsArray: this.allowedRange,
        filterable: true,
        withSpan: false,
        editable: this.attendance.canEdit
      };
    },
    user() {
      return {
        labelName: this.translations.field_user,
        value: this.attendance.user,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "user_id",
        optionsArray: false,
        filterable: false,
        searchQuery: this.fetchInternalUsers,
        withSpan: false,
        editable: this.attendance.canEditUsers
      };
    },
    atWork() {
      return {
        labelName: this.translations.field_at_work,
        value: this.textilizeBool(
          this.attendance.easyAttendanceActivity.atWork
        ),
        inputType: "text",
        attribute: "at_work",
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: false
      };
    },
    approvedAt() {
      return {
        labelName: this.translations.field_approved_at,
        value: this.dateFormat(this.attendance.approvedAt || ""),
        placeholder: "---",
        inputType: "text",
        attribute: "approved_at",
        optionsArray: false,
        withSpan: false,
        editable: false
      };
    },
    approvedBy() {
      return {
        labelName: this.translations.field_approved_by,
        value: this.attendance.approvedBy || "---",
        inputType: "autocomplete",
        attribute: "approved_by",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: false
      };
    },
    approvalStatus() {
      return {
        labelName: this.translations.easy_attendance_approval_status,
        value: {
          name: this.attendance.approvalStatus.value,
          key: this.attendance.approvalStatus.key
        },
        inputType: "autocomplete",
        attribute: "appproval_status",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: false
      };
    },
    startDate() {
      let type = "time";
      let attendanceRange = this.attendance.range;
      let range = true;
      let labelName = `${this.translations.easy_attendance_arrival} -> ${this.translations.easy_attendance_departure}`;
      let date = [this.attendance.arrival, this.attendance.departure];
      let attribute = ["arrival", "departure"];
      if (attendanceRange) {
        type = attendanceRange.key === "3" ? "date" : "time";
        range = false;
        date = this.attendance.arrival;
        labelName = this.translations.easy_attendance_arrival;
        attribute = "arrival";
      }
      return {
        labelName,
        placeholder: "---",
        date,
        inputType: type,
        attribute,
        optionsArray: false,
        withSpan: false,
        editable: this.attendance.canEdit,
        range,
        withLoading: false
      };
    },
    dueDate() {
      let type = "time";
      let range = this.attendance.range;
      let editable = true;
      if (range) {
        editable = false;
        if (range.key === "3") {
          editable = true;
          type = "date";
        }
      }
      return {
        labelName: this.translations.easy_attendance_departure,
        placeholder: "---",
        date: this.attendance.departure,
        inputType: type,
        attribute: "departure",
        optionsArray: false,
        withSpan: false,
        editable: this.attendance.canEdit && editable
      };
    },
    dateInput() {
      return {
        labelName: "Date",
        placeholder: "---",
        date: this.attendance.arrival,
        inputType: "date",
        attribute: "date",
        optionsArray: false,
        withSpan: false,
        editable: this.attendance.canEdit
      };
    },
    allowedActivities() {
      const activities = this.attendance.allowedActivities.map(activity => {
        return { name: activity.name, id: activity.id };
      });
      return activities;
    },
    allowedRange() {
      return this.attendance.allowedRanges;
    }
  },
  methods: {
    saveValue(name, payload) {
      this.$emit("save-value", { name, payload });
    },
    saveRange(name, payload) {
      let attributes = {};
      attributes = {
        range: payload.inputValue.key,
        non_work_start_time: {
          time: this.setStartDependsOnRange(payload.inputValue.key)
        }
      };
      this.$emit("change-range", { attributes, payload });
    },
    changeDate(name, payload) {
      let attributes = {};
      const date = payload.inputValue;
      const attendanceDate = moment(this.dateInput.date).format("YYYY-MM-DD");
      const range = this.range.value;
      const allDay = range && range.key === "3";
      const dateChange = name === "date";
      let time =
        name === "arrival" ? date : moment(this.startDate.date).format("HH:mm");
      if (allDay || dateChange) {
        let start = this.startDate.date;
        let end = this.dueDate.date;
        if (!allDay && dateChange) {
          start = this.startDate.date[0];
          end = this.dueDate.date;
        }
        attributes = {
          arrival: this.moveDate(date, start),
          departure: this.moveDate(date, end)
        };
      } else if (range) {
        attributes = {
          [name]: `${attendanceDate} ${date}`,
          non_work_start_time: { time }
        };
      } else {
        time = time[0];
        attributes = {
          arrival: `${attendanceDate} ${date[0]}`,
          departure: `${attendanceDate} ${date[1]}`,
          non_work_start_time: { time }
        };
      }
      this.$emit("change-range", { attributes, payload });
    },
    async fetchInternalUsers(id, term) {
      const searchTerm = term || "";
      const response = await fetch(
        `/easy_autocompletes/internal_users?term=${searchTerm}`
      );
      let json = await response.json();
      const users = json.users;
      const assignees = users.map(user => {
        return {
          value: user.value,
          id: user.id
        };
      });
      return assignees;
    },
    setStartDependsOnRange(range) {
      let start = "";
      if (range === "2") {
        const hours = new Date(this.attendance.evening).getHours();
        const halfDay = this.attendance.workingTime / 2;
        start = new Date().setHours(hours - halfDay, 0, 0, 0);
      } else {
        start = this.attendance.morning;
      }
      return moment(start).format("HH:mm");
    }
  }
};
</script>

<style scoped></style>
