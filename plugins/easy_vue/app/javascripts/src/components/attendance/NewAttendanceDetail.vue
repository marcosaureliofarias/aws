<template>
  <div :class="`${bem.ify(bem.block, 'new-attendance-detail')} ${bem.ify(bem.block, 'attributes--new')}`">
    <Attribute
      :id="id"
      :bem="bem"
      :data="activityList"
      :class="bem.ify(bem.block, 'attribute', 'long')"
      @child-value-change="saveValue('easyAttendanceActivity', $event)"
    />
    <div v-if="activityList.value.name" :class="`${bem.block}__attribute-step`">
      <Attribute
        :id="id"
        :bem="bem"
        :multiple="true"
        :required="true"
        :data="user"
        :class="bem.ify(bem.block, 'attribute', 'long')"
        @child-value-change="saveValue('user', $event)"
      />
      <Attribute
        v-if="showDateInput"
        :id="id"
        :bem="bem"
        :data="dateInput"
        @child-value-change="changeDate('date', $event)"
      />
      <div :class="`${bem.block}__attribute-group`">
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
      </div>
      <div v-if="!attendance.range" :class="`${bem.block}__attribute-group`">
        <Attribute
          :id="id"
          :bem="bem"
          :data="repeat"
          @child-value-change="saveValue('repeat', $event)"
        />
        <Attribute
          v-if="attendance.repeat"
          :id="id"
          :bem="bem"
          :data="repeatDate"
          @child-value-change="saveValue('repeatDate', $event)"
        />
      </div>
      <Attribute
        v-if="showPortion"
        :id="id"
        :bem="bem"
        :data="range"
        :class="bem.ify(bem.block, 'attribute', 'long')"
        @child-value-change="saveRange('range', $event)"
      />
      <EditorBox
        :config="descriptionConfig"
        :value="attendance.description"
        :lazy="true"
        :textile="textile"
        :translations="translations"
        :bem="bem"
        :wip-notify="false"
        @valueChanged="$emit('description:changed', $event)"
      />
    </div>
  </div>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import EditorBox from "../generalComponents/EditorBox";

export default {
  name: "Detail",
  components: { Attribute, EditorBox },
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
    },
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
      alignment: null,
      descriptionConfig: {
        placeholder: "Description",
        edit: false,
        editId: "",
        clearOnSave: false,
        showButtons: false,
        id: "description",
        startupFocus: false
      }
    };
  },
  computed: {
    attendance() {
      return this.$props.data;
    },
    textile() {
      if (!this.$store.state.allSettings) return false;
      return this.$store.state.allSettings.text_formatting !== "HTML";
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
    activityList() {
      const activity = this.attendance.easyAttendanceActivity;
      const value = !activity
        ? { name: "", id: "" }
        : {
            name: this.attendance.easyAttendanceActivity.name,
            id: this.attendance.easyAttendanceActivity.id
          };
      return {
        labelName: this.translations.field_easy_attendance_activity,
        value,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "easy_attendance_activity_id",
        optionsArray: this.allowedActivities,
        filterable: true,
        withSpan: false,
        editable: true,
        withLoading: false
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
        editable: true,
        withLoading: false
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
        editable: true,
        withLoading: false
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
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName,
        placeholder: "---",
        date: date,
        inputType: type,
        attribute,
        optionsArray: false,
        withSpan: false,
        editable: true,
        range,
        withLoading: false
      };
    },
    dateInput() {
      return {
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName: this.translations.label_date,
        placeholder: "---",
        date: this.attendance.arrival,
        inputType: "date",
        attribute: "date",
        optionsArray: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    repeatDate() {
      return {
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName: this.translations.label_date,
        placeholder: "---",
        date: this.attendance.repeatDate,
        inputType: "date",
        attribute: "repeat_date",
        optionsArray: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    repeat() {
      return {
        labelName: "Repeat ?",
        value: this.attendance.repeat,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "bool",
        attribute: "repeat",
        tagStyle: "check_box",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: true,
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
          editable = this.attendance.canEdit;
          type = "date";
        }
      }
      return {
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName: this.translations.easy_attendance_departure,
        placeholder: "---",
        date: this.attendance.departure,
        inputType: type,
        attribute: "departure",
        optionsArray: false,
        withSpan: false,
        editable,
        withLoading: false
      };
    },
    allowedActivities() {
      const activities = this.attendance.allowedActivities.map((activity) => {
        return { name: activity.name, id: activity.id };
      });
      return activities;
    },
    allowedRange() {
      return this.attendance.allowedRanges;
    },
  },
  methods: {
    saveValue(name, payload) {
      this.$emit("save-value", { name, payload });
    },
    saveRange(name, payload) {
      const attributes = {
        range: payload.inputValue,
        non_work_start_time: {
          time: this.setStartDependsOnRange(payload.inputValue.key)
        },
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
          arrival: name === "arrival" ? this.moveDate(date, start) : this.moveDate(attendanceDate, start),
          departure: name === "departure" ? this.moveDate(date, end) : this.moveDate(attendanceDate, end),
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
      this.$emit("change-timerange", { attributes, payload });
    },
    async fetchInternalUsers(id, term) {
      const searchTerm = term || "";
      const response = await fetch(
        `/easy_autocompletes/internal_users?term=${searchTerm}`
      );
      let json = await response.json();
      const users = json.users;
      const assignees = users.map((user) => {
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
