<template>
  <section id="checklist_anchor" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading') + ' icon--add'">
      {{ translations.sectionName }}
    </h2>
    <div
      v-for="(list, i) in getLists"
      :key="i"
      :class="bem.ify(block, `${element}-wrapper`)"
    >
      <h3
        :class="
          bem.ify(block, 'heading' + ' ' + bem.ify(block, `${element}-heading`))
        "
      >
        <a
          v-if="list.deletable"
          :class="bem.ify(block, `${element}-delete`) + ' icon icon-del'"
          href="javascript:void(false);"
          @click="deleteCheckList(list)"
        />
        <InlineInput
          :data="checkListTitleInput"
          :value="list.title || list.title.inputValue"
          @child-value-change="updateListTitle($event, list)"
        />
        <ProgressBar :bem="bem" :ratio="list.ratio" type="checkListRatio" />
      </h3>
      <ul :class="bem.ify(block, element)">
        <li
          v-for="(item, j) in list.items"
          :key="j"
          :class="[
            item.isDone
              ? bem.ify(block, `${element}-item`) + ' done'
              : bem.ify(block, `${element}-item`)
          ]"
        >
          <input
            :id="j"
            v-model="item.isDone"
            :disabled="checkboxDisabledByPerms(item)"
            type="checkbox"
            name="isDone"
            @change="getCheckListRatio(list, item, true)"
          />
          <InlineInput
            :data="itemInput"
            :value="item.title"
            @child-value-change="updateItem($event, item, list)"
          />
          <a
            v-if="item.deletable"
            :class="'icon icon-del'"
            href="javascript:void(false);"
            @click.stop="deleteCheckListItem(item, list)"
          />
        </li>
      </ul>
      <input
        v-if="itemFormShowId === list.id"
        ref="itemNameInput"
        v-model.trim="list.itemName"
        type="text"
        :class="bem.ify(block, `${element}-input`)"
        @keydown.enter.prevent="addItem(list, i)"
      />
      <a
        v-if="showCreateChecklistItemBtn(list)"
        class="button-positive"
        @click.stop="createItem(list, i)"
      >
        {{ translations.createCheckListItem }}
      </a>
      <a
        v-if="itemFormShowId === list.id"
        class="button-positive"
        @click.stop="addItem(list, i)"
      >
        {{ translations.saveButton }}
      </a>
      <a v-if="itemFormShowId === list.id" class="button" @click="closeAddItem(list)">
        {{ translations.cancelButton }}
      </a>
      <hr />
    </div>
    <input
      v-show="listFormShow"
      ref="createdListInput"
      v-model.trim="listTitle"
      type="text"
      :class="bem.ify(block, `${element}-input`)"
      @keydown.enter.prevent="addList()"
    />
    <a
      v-if="showCreateChecklistBtn"
      class="button-positive"
      @click="showCreateForm()"
    >
      {{ translations.createCheckList }}
    </a>
    <a v-if="listFormShow" class="button-positive" @click="addList()">
      {{ translations.saveButton }}
    </a>
    <a v-if="listFormShow" class="button" @click="listFormShow = false">
      {{ translations.cancelButton }}
    </a>
  </section>
</template>

<script>
import ProgressBar from "./../generalComponents/ProgressBar";
import InlineInput from "./../generalComponents/InlineInput";
import checkListsQuery from "../../graphql/checklists";

export default {
  name: "CheckList",
  components: {
    ProgressBar,
    InlineInput
  },
  props: {
    bem: Object,
    checklists: Array
  },
  data() {
    return {
      translations: {
        sectionName: this.$store.state.allLocales.label_easy_checklist_plural,
        createCheckList: this.$store.state.allLocales.button_new_easy_checklist,
        saveButton: this.$store.state.allLocales.button_save,
        // eslint-disable-next-line prettier/prettier
        createCheckListItem: this.$store.state.allLocales
          .button_new_easy_checklist_item,
        cancelButton: this.$store.state.allLocales.button_cancel
      },
      lists: this.$props.checklists,
      listTitle: null,
      listFormShow: false,
      itemFormShowId: null,
      itemInput: {
        labelName: "checklist item title",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "text",
        editable: true,
        withSpan: false
      },
      checkListTitleInput: {
        labelName: "checklist title",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "text",
        editable: true,
        withSpan: false
      },
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    permissions() {
      return {
        createChecklist: this.$store.state.issue.project.addableChecklists,
        createChecklistItem: this.$store.state.issue.project
          .addableChecklistItems
      };
    },
    showCreateChecklistBtn() {
      return this.permissions.createChecklist && !this.listFormShow;
    },
    showCreateChecklistItemBtn() {
      return list => {
        return this.itemFormShowId !== list.id && this.permissions.createChecklistItem;
      };
    },
    getLists() {
      const checklists = [...this.checklists];
      checklists.forEach(checklist => {
        if (checklist.items.length) {
          checklist.items.reverse();
        }
      });
      return this.checklists;
    }
  },
  methods: {
    checkboxDisabledByPerms(item) {
      if (item.canEnable && item.canDisable) return false;
      if (item.isDone && !item.canDisable) return true;
      if (!item.isDone && !item.canEnable) return true;
      return false;
    },
    showCreateForm() {
      this.listFormShow = true;
      this.$nextTick(() => {
        this.$refs.createdListInput.focus();
      });
      if (!this.lists.length) return;
      this.lists.forEach(el => {
        el.itemFormShow = false;
      });
    },
    async addList() {
      const easy_checklist = {
        name: this.listTitle,
        entity_type: "Issue",
        entity_id: this.$store.state.issue.id
      };
      if (!easy_checklist.name) return;
      const payload = {
        reqBody: { easy_checklist },
        reqType: "post",
        url: `${window.urlPrefix}/easy_checklists.json`
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      await this.fetchChecklists();
      this.listTitle = "";
    },
    createItem(list) {
      this.itemFormShowId = list.id;
      this.$nextTick(() => {
        this.$refs.itemNameInput[0].focus();
      });
    },
    async addItem(list, i) {
      const id = list.id;
      const easy_checklist_item = {
        subject: list.itemName
      };
      const payload = {
        reqBody: { easy_checklist_item, id },
        url: `${window.urlPrefix}/easy_checklist_items.json`,
        reqType: "post"
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      await this.fetchChecklists();
      this.listTitle = "";
      list.itemName = "";
      this.createItem(list, i);
    },
    closeAddItem(list) {
      list.itemName = "";
      this.itemFormShowId = null;
    },
    getCheckListRatio(list, item, update) {
      this.$emit("ratioChanged", list);
      if (!list.items.length) return 0;
      const done = list.items.filter(el => el.isDone).length;
      const all = list.items.length;
      list.ratio = this.getTotalRatio(done, all);
      if (update) this.updateItem(null, item, list);
    },
    async deleteCheckList(list) {
      const payload = {
        url: `${window.urlPrefix}/easy_checklists/${list.id}.json`,
        reqType: "delete",
        reqBody: {}
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      await this.fetchChecklists();
    },
    async deleteCheckListItem(item, list) {
      const payload = {
        url: `${window.urlPrefix}/easy_checklists/${list.id}/item/${item.id}.json`,
        reqType: "delete",
        reqBody: {}
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
      this.getCheckListRatio(list, item, false);
      await this.fetchChecklists();
    },
    async updateItem(value, item, list) {
      const subject = value ? value.inputValue : item.title;
      const payload = {
        reqBody: {
          id: list.id,
          easy_checklist_item_id: item.id,
          done: item.isDone ? "1" : "0",
          easy_checklist_item: { subject }
        },
        url: `/easy_checklists/${list.id}/item/${item.id}.json`,
        commit: {
          name: "setChecklistsItemTitle",
          data: {
            id: list.id,
            list,
            item,
            subject
          }
        }
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
    },
    async updateListTitle(value, list) {
      const name = value.inputValue;
      const id = list.id;
      const payload = {
        reqBody: {
          id,
          easy_checklist: { name }
        },
        url: `/easy_checklists/${list.id}.json`,
        commit: {
          name: "setChecklist",
          data: {
            id,
            list,
            name
          }
        }
      };
      await this.$store.dispatch("saveIssueStateValue", payload);
    },
    async fetchChecklists() {
      const payload = {
        name: "checklists",
        apolloQuery: {
          query: checkListsQuery,
          variables: {
            id: this.$store.state.issue.id
          }
        }
      };
      await this.$store.dispatch("fetchIssueValue", payload);
    }
  }
};
</script>

<style lang="scss" scoped></style>
