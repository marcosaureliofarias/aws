<template>
  <section v-if="showList" :id="anchor" :class="bem.ify(block, 'section')">
    <h2 v-if="!inPopUp" :class="bem.ify(block, 'heading') + ' icon-tree'">
      {{ data.sectionName }}
    </h2>
    <div :class="bem.ify(block, `${element}-wrapper`)">
      <TableBuilder
        :head-data="rebasedHeadData"
        :body-data="rebasedBodyData"
        :options="options"
        :table-action-buttons="inPopUp ? [] : tableActionButtons"
        class="list"
        @row-checked="$emit('item-checked', $event)"
      />
    </div>
  </section>
</template>

<script>
import TableBuilder from "../generalComponents/TableBuilder";

export default {
  name: "TaskList",
  components: {
    TableBuilder
  },
  props: {
    task: Object,
    data: {
      type: Object,
      default: () => {}
    },
    bem: Object,
    inPopUp: {
      type: Boolean,
      default: false
    },
    block: {
      type: String,
      default: "vue-modal"
    }
  },
  data() {
    return {
      translations: this.$store.state.allLocales,
      options: {
        reverseBodyOrder: true,
        showRowInput: this.$props.data.showRowInput,
        rowInputType: this.$props.data.rowInputType
      },
      element: this.$options.name.toLowerCase(),
      tableActionButtons: [
        {
          classString: "",
          icon: "icon icon-view-modal",
          title: this.$props.data.editTitle,
          permissionName: "edit",
          cb: payload => this.$emit("openTask", payload)
        },
        {
          classString: "",
          icon: this.$props.data.delete ? this.$props.data.delete.icon : "",
          title: this.$props.data.delete? this.$props.data.delete.title : "",
          permissionName: "delete",
          cb: async payload => {
            await this.$emit("removeItem", payload);
            this.$delete(this.$props.data.list, payload.row.index);
          }
        }
      ]
    };
  },
  computed: {
    taskList() {
      return this.$props.data.list;
    },
    anchor() {
      if (!this.$props.data || !this.$props.data.anchor) return "";
      return this.$props.data.anchor.substr(1);
    },
    showList() {
      const listItem = this.$props.data.list[0];
      if (listItem) return Object.keys(listItem).length > 3;
      else return false;
    },
    rebasedBodyData() {
      const data = this.$props.data;
      if (!this.taskList) return [];
      const dataArray = this.taskList.map((item, i) => {
        const subject = `<a href="${window.urlPrefix}/issues/${item.id}" target="_blank">${item.subject}</a>`;
          const assignee = item.assignedTo
            ? `<a href="${window.urlPrefix}/users/${item.assignedTo.id}/profile" target="_blank">
              ${item.assignedTo.name}
            </a>`
            : "---";
        const row = {
          id: item.id,
          element: item,
          index: i,
          body: [
            { label: subject },
            { label: item.status.name },
            { label: `${item.doneRatio}%` },
            { label: assignee }
          ],
          buttonsPermissions: data.permissions
        };
        if (item.relation) {
          row.body.unshift({ label: item.relation });
        }
        return row;
      });
      return dataArray;
    },
    rebasedHeadData() {
      const columns = [
        { label: this.translations.field_subject },
        { label: this.translations.field_status },
        { label: this.translations.label_progress },
        { label: this.translations.field_assigned_to }
      ];
      if (this.taskList[0].relation) {
        columns.unshift({ label: this.translations.field_relations_from });
      }
      return [ columns ];
    }
  }
};
</script>

<style scoped></style>
