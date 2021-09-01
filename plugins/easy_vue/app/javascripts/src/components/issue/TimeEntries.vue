<template>
  <div>
    <TableBuilder
      :head-data="rebasedHeadData"
      :body-data="rebasedBodyData"
      :options="options"
      :table-action-buttons="tableActionButtons"
      class="list"
    />
  </div>
</template>

<script>
import TableBuilder from "../generalComponents/TableBuilder";

export default {
  name: "TimeEntries",
  components: {
    TableBuilder
  },
  props: {
    task: Object,
    bem: Object,
    spentHours: Number
  },
  data() {
    return {
      translations: this.$store.state.allLocales,
      options: {
        reverseBodyOrder: true
      },
      tableActionButtons: [
        {
          classString: "",
          title: this.$store.state.allLocales.button_edit,
          icon: "icon icon-edit",
          permissionName: "edit",
          cb: payload => this.$emit("row-edit", payload)
        },
        {
          classString: "",
          title: this.$store.state.allLocales.button_delete,
          icon: "icon icon-del",
          permissionName: "delete",
          cb: payload => this.$emit("row-delete", payload)
        }
      ]
    };
  },
  computed: {
    rebasedBodyData() {
      let dataArray = [];
      if (!this.$props.task.timeEntries) return dataArray;
      this.$props.task.timeEntries.forEach(timeEntryObj => {
        const row = {
          id: timeEntryObj.id,
          unformattedEntry: timeEntryObj,
          buttonsPermissions: {
            edit: timeEntryObj.editable,
            delete: timeEntryObj.deletable
          },
          body: [
            { label: this.dateFormat(timeEntryObj.spentOn) },
            { label: timeEntryObj.user.name },
            { label: timeEntryObj.comments },
            { label: parseFloat(timeEntryObj.hours).toFixed(2) }
          ]
        };
        dataArray.push(row);
      });
      return dataArray;
    },
    rebasedHeadData() {
      return [
        [
          { label: this.translations.label_date },
          { label: this.translations.field_user },
          { label: this.translations.label_comment },
          { label: this.translations.label_spent_time },
        ],
        [
          { label: this.translations.label_total_time },
          { label: "", colspan: 2 },
          { label: this.$props.spentHours.toFixed(2) + " h" }
        ]
      ];
    }
  }
};
</script>

<style scoped></style>
