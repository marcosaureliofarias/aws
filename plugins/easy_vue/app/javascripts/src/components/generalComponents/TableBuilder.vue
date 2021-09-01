<template>
  <table class="vue-table">
    <thead class="vue-table__head">
      <tr
        v-for="(row, i) in headData"
        :key="i"
        class="vue-table__row vue-table__row--head"
      >
        <th v-if="options.showRowInput">
          <a
            v-if="rowInputType === 'checkbox' && options.showToggleAll"
            href="#"
            class="icon icon-checked"
            @click.prevent="toggleAll"
          />
        </th>
        <th
          v-for="(th, index) in row"
          :key="index"
          :colspan="th.colspan ? th.colspan : 1"
          class="vue-table__element"
        >
          {{ th.label }}
        </th>
        <th />
      </tr>
    </thead>
    <tbody v-if="bodyArray.length" class="vue-table__body">
      <tr
        v-for="row in bodyArray"
        :key="row.id"
        class="vue-table__row"
      >
        <td v-if="options.showRowInput">
          <input
            v-model="row.element.checked"
            :type="rowInputType"
            :name="row.id"
            @change="rowInputChecked(row)"
          />
        </td>
        <td
          v-for="(td, index) in row.body"
          :key="index"
          :colspan="td.colspan ? td.colspan : 1"
          class="vue-table__element"
          @click="rowCheck(row)"
        >
          <div class="vue-table__element-label" style="display: none">
            {{ headData[0][index].label }}
          </div>
          <div class="vue-table__element-content" v-html="td.label" />
        </td>
        <td class="vue-table__element ">
          <div class="vue-table__buttons">
            <span v-for="(action, i) in tableActionButtons" :key="i">
              <a
                v-if="buttonVisibleWithPermissions(action, row)"
                href="#"
                :class="`${action.icon} ${action.classString}`"
                :title="action.title"
                @click="action.cb({ event: $event, row: row })"
              >
                {{ action.label || "" }}
              </a>
            </span>
          </div>
        </td>
      </tr>
    </tbody>
    <tbody v-else class="vue-table__body">
      <tr class="vue-table__row">
        <td colspan="100%" class="vue-table__body-element">
          <div class="flash nodata">
            No data
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
export default {
  name: "TableBuilder",
  props: {
    headData: Array,
    bodyData: Array,
    options: {
      type: Object,
      default: () => {}
    },
    tableActionButtons: Array,
    checked: {
      type: Array,
      default: () => []
    },
  },
  data() {
    return {
      rowInputType: this.options.rowInputType
        ? this.options.rowInputType
        : "checkbox",
        allChecked: false
    };
  },
  computed: {
    bodyArray() {
      const options = this.$props.options;
      if (
        options.hasOwnProperty("reverseBodyOrder") &&
        options.reverseBodyOrder
      ) {
        return this.bodyData.slice().reverse();
      }
      return this.bodyData;
    }
  },
  methods: {
    buttonVisibleWithPermissions(btnAction, row) {
      // no perms are set -> show btn
      if (!row.buttonsPermissions || !btnAction.permissionName) return true;
      if (!row.buttonsPermissions.hasOwnProperty(btnAction.permissionName)) {
        return true;
      }
      const permission = row.buttonsPermissions[btnAction.permissionName];
      return permission;
    },
    rowInputChecked(row) {
      const payload = {
        item: row.element
      };
      this.$emit("row-checked", payload);
    },
    rowCheck(row) {
      if (!row || !row.element) return;
      row.element.checked = !row.element.checked;
      this.rowInputChecked(row);
    },
    toggleAll() {
      this.bodyArray.forEach(row => {
        if (this.allChecked) {
          row.element.checked = false;
        } else {
          row.element.checked = true;
        }
        this.rowInputChecked(row);
      });
    }
  }
};
</script>

<style scoped></style>
