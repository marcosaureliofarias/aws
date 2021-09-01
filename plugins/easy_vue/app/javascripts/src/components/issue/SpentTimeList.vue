<template>
  <section id="spent_time_anchor" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(bem.block, 'heading') + ' icon--time'">
      {{ this.$store.state.allLocales.label_spent_time }}
    </h2>
    <div :class="bem.ify(block, modifier)" style="position: relative;">
      <LogTime
        v-if="$props.task.addableTimeEntries || editTimeEntry"
        :task="task"
        :bem="bem"
        :block="block"
        :textile="textile"
        :edit-time-entry="editTimeEntry"
        :edit-time-entry-payload="editTimeEntryPayload"
        :cf-values="cfValues"
        :activity-id="activityId"
        @edit-cancel="handleCancel"
        @activity:change="handleActivityChange"
      />
      <TimeEntries
        :task="task"
        :bem="bem"
        :spent-hours="spentHours"
        @row-edit="setEditTimeEntry"
        @row-delete="deleteConfirm"
      />
      <PopUp
        v-if="showPopup"
        :bem="bem"
        :component="'Confirm'"
        :translations="translations"
        :custom-styles="customPopupStyles"
        :align="alignment"
        @confirmed="deleteTimeEntry($event)"
      />
    </div>
  </section>
</template>

<script>
import TimeEntries from "./TimeEntries";
import LogTime from "./LogTime";
import issueHelper from "../../store/actionHelpers";
import PopUp from "../generalComponents/PopUp";
import LogTimeFetcher from "../../plugins/LogTime";

export default {
  name: "SpentTimeList",
  components: {
    TimeEntries,
    LogTime,
    PopUp
  },
  props: {
    task: Object,
    bem: Object,
    spentHours: Number,
    isMobile: {
      type: Boolean,
      default: false
    },
    block: {
      type: String,
      default() {
        return "";
      }
    },
    textile: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase(),
      editTimeEntry: false,
      editTimeEntryPayload: {},
      showPopup: false,
      translations: this.$store.state.allLocales,
      payloadToDelete: null,
      alignment: null,
      popupHeight: 100,
      cfData: [],
      cfValues: {},
      activityId: this.$props.task.project.activitiesPerRole[0].id
    };
  },
  computed: {
    customPopupStyles() {
      return {
        position: "fixed !important",
        height: `${this.popupHeight}px !important`,
        width: "auto",
        "max-width": "200px"
      };
    }
  },
  methods: {
    setEditTimeEntry(payload) {
      this.scrollTo("#spent_time_anchor");
      this.editTimeEntry = true;
      this.editTimeEntryPayload = payload.row;
      this.getTimeEntryData(payload.row.id);
    },
    deleteConfirm(payload, isMobile) {
      const event = payload.event;
      const options = {
        topOffs: event.y - this.popupHeight,
        rightOffs: event.y - this.popupHeight,
        leftOffs: event.x
      };
      this.alignment = this.getAlignment(event, options, isMobile);
      this.showPopup = true;
      this.payloadToDelete = payload.row;
    },
    deleteTimeEntry(accepted) {
      if (!accepted) {
        this.cancelDeleting();
        return;
      }
      const timeEntryID = this.payloadToDelete.id;
      const newTimeEntryArr = issueHelper.deleteByID(
        this.$props.task.timeEntries,
        timeEntryID
      );
      // delete it from server and modify timeEntriesState
      const deletePayload = {
        reqType: "delete",
        url: `${window.urlPrefix}/easy_time_entries/${timeEntryID}.json`,
        name: "timeEntries",
        value: { timeEntries: newTimeEntryArr }
      };
      this.$store.dispatch("saveIssueStateValue", deletePayload);
      this.cancelDeleting();
    },
    cancelDeleting() {
      this.payloadToDelete = null;
      this.showPopup = false;
    },
    async getTimeEntryData(timeEntryId) {
      const route = `${window.urlPrefix}/easy_time_entries`;
      const params = {
        method: "GET",
        route: route,
        timeEntryId: timeEntryId || this.timeEntryId
      };
      const timeEntry = new LogTimeFetcher(params);
      const timeEntryData = await timeEntry.update();
      this.cfData = timeEntryData.time_entry.custom_fields;
      this.activityId = timeEntryData.time_entry.activity.id.toString();
      this.setCFValues();
    },
    setCFValues() {
      let cfValues = {};
      this.cfData.forEach((cf) => {
        cfValues[cf.id] = cf.value;
      });
      this.cfValues = cfValues;
    },
    handleCancel() {
      this.editTimeEntry = false;
      this.activityId = this.$props.task.project.activitiesPerRole[0].id;
    },
    handleActivityChange(e) {
      this.activityId = e;
    }
  }
};
</script>
<style scoped></style>
