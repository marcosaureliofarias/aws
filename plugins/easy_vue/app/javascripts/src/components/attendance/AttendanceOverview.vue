<template>
  <section :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading')">
      {{ translations["easy_attendance_approval-1"] }}
    </h2>
    <div :class="bem.ify(block, `${element}-wrapper`)">
      <TableBuilder
        :head-data="rebasedHeadData"
        :body-data="rebasedBodyData"
        :options="options"
        :class="`list ${element}-list`"
        @row-checked="addToAttendanceArray($event)"
      />
      <EditorBox
        ref="description"
        :value="''"
        :config="ckeditorConfig"
        :translations="translations"
        :textile="options.data.settings.textile"
        :bem="bem"
        @cancel-edit="clearChanges"
        @valueChanged="saveDescription($event)"
      />
    </div>
    <div class="vue-modal__button-panel">
      <span
        v-for="(button, i) in buttons"
        :key="i"
        style="margin: 0.4rem 0.2rem"
      >
        <button
          v-if="button.show"
          :class="button.class"
          :disabled="button.disabled"
          @click="button.func()"
        >
          {{ button.name }}
        </button>
      </span>
    </div>
  </section>
</template>

<script>
import TableBuilder from "../generalComponents/TableBuilder";
import EditorBox from "../generalComponents/EditorBox";

export default {
  name: "AttendanceOverview",
  components: {
    TableBuilder,
    EditorBox
  },
  props: {
    bem: Object,
    translations: Object,
    options: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      ckeditorConfig: {
        edit: true,
        clearOnSave: true,
        showButtons: false,
        startupFocus: false,
        id: "description"
      },
      actionIds: [],
      attendanceDescription: "",
      list: this.$props.options.attendanceList,
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    rebasedBodyData() {
      let dataArray = [];
      if (!this.$props.options.attendanceList) return dataArray;
      this.$props.options.attendanceList.forEach((attendance, i) => {
        const assignee = `<a href="/users/${attendance.user.id}/profile" target="_blank">${attendance.user.name}</a>`;
        const row = {
          id: attendance.id,
          element: attendance,
          index: i,
          body: [
            { label: assignee },
            { label: attendance.easyAttendanceActivity.name },
            { label: this.dateFormat(attendance.departure) },
            { label: this.dateFormat(attendance.arrival) },
            { label: attendance.approvalStatus.value }
          ]
        };
        dataArray.push(row);
      });
      return dataArray;
    },
    rebasedHeadData() {
      return [
        [
          { label: this.translations.field_user },
          { label: this.translations.field_activity },
          { label: this.translations.label_date_from },
          { label: this.translations.label_date_to },
          { label: this.translations.field_status }
        ]
      ];
    },
    buttons() {
      return [
        {
          name: this.translations.easy_attendance_approval_actions_2,
          func: () => {
            this.attendanceApproved("1", this.actionIds, this.attendanceDescription);
            this.$emit("onBlur");
          },
          show: true,
          class: "button-positive",
          disabled: false
        },
        {
          name: this.translations.easy_attendance_approval_actions_3,
          func: () => {
            this.attendanceApproved("0", this.actionIds, this.attendanceDescription);
            this.$emit("onBlur");
          },
          show: true,
          class: "button-negative",
          disabled: false
        },
        {
          name: this.translations.button_close,
          func: () => {
            this.$emit("onBlur");
          },
          show: true,
          class: "button",
          disabled: false
        }
      ];
    }
  },
  methods: {
    clearChanges() {
      this.wipActivated(false);
      if (this.$store.state.allSettings.text_formatting !== "HTML") {
        this.editorInput = "";
      } else {
        CKEDITOR.instances[this.commentAddConfig.id].setData("");
      }
    },
    addToAttendanceArray(payload) {
      const { item } = payload;
      item.checked ? this.actionIds.push(item.id) : this.actionIds.pop(item.id);
    },
    saveDescription(value) {
      this.attendanceDescription = value;
    }
  }
};
</script>

<style lang="scss" scoped></style>
