<template>
  <div :class="`${bem.ify(bem.block, 'new-activity-detail')} ${bem.ify(bem.block, 'attributes--new')}`">
    <Attribute
      :id="id"
      :bem="bem"
      :data="activityType"
      :required="true"
      @child-value-change="saveValue($event, 'entityType')"
    />
    <Attribute
      v-if="showEntity"
      :id="id"
      :bem="bem"
      :data="entity"
      :required="true"
      @child-value-change="saveValue($event, 'entity')"
    />
    <transition name="slide-fade">
      <div v-if="showSecondPart" :class="`${bem.block}__attribute-step`">
        <Attribute
          :id="id"
          :bem="bem"
          :data="date"
          :required="true"
          @child-value-change="changeRange($event, 'date')"
        />
        <div :class="`${bem.block}__attribute-group`">
          <Attribute
            :id="id"
            :bem="bem"
            :data="startDate"
            :required="true"
            @child-value-change="changeRange($event, 'startTime')"
          />
          <Attribute
            :id="id"
            class="vue-modal__attribute-side"
            :bem="bem"
            :data="allDay"
            @child-value-change="saveValue($event, 'allDay')"
          />
        </div>
        <Attribute
          :id="id"
          :bem="bem"
          :data="isFinished"
          @child-value-change="saveValue($event, 'isFinished')"
        />
        <Attribute
          :id="id"
          :bem="bem"
          :data="category"
          @child-value-change="saveValue($event, 'category')"
        />
        <Attribute
          :id="id"
          :bem="bem"
          :multiple="true"
          :data="users"
          :required="true"
          @child-value-change="multiselectChange($event, 'users')"
        />
        <Attribute
          :id="id"
          :bem="bem"
          :multiple="true"
          :data="contacts"
          @child-value-change="multiselectChange($event, 'Contact')"
        />
        <EditorBox
          :config="descriptionConfig"
          :value="activity.description"
          :lazy="true"
          :textile="textile"
          :translations="translations"
          :bem="bem"
          :wip-notify="false"
          @valueChanged="$emit('description:changed', $event)"
        />
      </div>
    </transition>
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
    }
  },
  data() {
    return {
      showEntity: true,
      oldEntity: {},
      descriptionConfig: {
        placeholder: "Description",
        edit: false,
        editId: "",
        clearOnSave: false,
        showButtons: false,
        id: "description",
        startupFocus: false,
      }
    };
  },
  computed: {
    activity() {
      return this.$props.data;
    },
    showSecondPart() {
      return this.activityType.value && this.entity.value;
    },
    textile() {
      if (!this.$store.state.allSettings) return false;
      return this.$store.state.allSettings.text_formatting !== "HTML";
    },
    activityType() {
      return {
        labelName: this.translations.field_type,
        value: this.activity.entityType,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "entity_type",
        optionsArray: this.activity.availableTypes,
        filterable: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    allDay() {
      return {
        labelName: this.translations.field_all_day,
        value: this.activity.allDay,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "bool",
        attribute: "all_day",
        tagStyle: "check_box",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    entity() {
      return {
        labelName: this.activity.entityType.value,
        value: this.activity.entity.value,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "entity_id",
        searchQuery: this.fetchEntyties,
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    category() {
      return {
        labelName: this.translations.field_category,
        value: this.activity.category,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "category_id",
        optionsArray: this.activity.categories,
        filterable: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    isFinished() {
      return {
        labelName: this.translations.field_easy_entity_activity_finished,
        value: this.activity.isFinished,
        inputType: "bool",
        attribute: "is_finished",
        tagStyle: "check_box",
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    users() {
      return {
        labelName: this.translations.label_user_plural,
        value: this.activity.users,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "principal",
        searchQuery: this.fetchUsers,
        optionsArray: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    contacts() {
      return {
        labelName: this.translations.label_easy_contacts,
        value: this.activity.Contact,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "contact",
        searchQuery: this.fetchContacts,
        optionsArray: false,
        withSpan: false,
        editable: true,
        withLoading: false
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
        editable: false,
        withLoading: false
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
        attribute: "approval_status",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: false,
        withLoading: false
      };
    },
    date() {
      return {
        labelName: this.translations.label_date,
        date: this.activity.startTime,
        inputType: "date",
        attribute: "date",
        optionsArray: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    },
    startDate() {
      return {
        labelName: `${this.translations.label_date_from} -> ${this.translations.label_date_to}`,
        date: [this.activity.startTime, this.activity.endTime],
        inputType: "time",
        attribute: ["start_date", "due_date"],
        optionsArray: false,
        withSpan: false,
        editable: true,
        disabled: this.allDay.value,
        range: true,
        withLoading: false
      };
    }
  },
  methods: {
    async saveValue(payload, name) {
      this.$emit("save-value", { name, payload });
      if (name === "entityType") {
        this.showEntity = false;
        await this.$nextTick();
        this.showEntity = true;
      }
    },
    changeRange(payload, name) {
      const date = payload.inputValue;
      const start = this.activity.startTime;
      const end = this.activity.endTime;
      let attributes = {};
      if (this.allDay.value || name === "date") {
        attributes = {
          startTime: this.moveDate(date, start),
          endTime: this.moveDate(date, end),
          date
        };
      } else {
        const dateString =
          name === "date"
            ? moment(date).format("YYYY-MM-DD")
            : moment(start).format("YYYY-MM-DD");
        attributes = {
          startTime: `${moment(dateString).format("YYYY-MM-DD")} ${date[0]}`,
          endTime: `${moment(dateString).format("YYYY-MM-DD")} ${date[1]}`
        };
      }
      this.$emit("change-range", { attributes, payload, name });
    },
    async fetchUsers(id, term) {
      const searchTerm = term || "";
      const response = await fetch(
        `/easy_autocompletes/users?term=${searchTerm}`
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
    async fetchContacts(id, term) {
      const searchTerm = term || "";
      const response = await fetch(
        `/easy_autocompletes/easy_contacts_visible_contacts?term=${searchTerm}`
      );
      let json = await response.json();
      const contacts = json.easy_contacts;
      return contacts;
    },
    async fetchEntyties(id, term) {
      const searchTerm = term || "";
      const entityAutocompleteTypes = {
        "EasyCrmCase": "get_visible_easy_crm_cases",
        "EasyContact": "easy_contacts_visible_contacts",
        "EasyPersonalContact": "easy_personal_contacts_visible",
        "EasyPartner": "easy_partners",
        "EasyLead": "easy_leads_visible"
      };
      const entityAutocompleteType = entityAutocompleteTypes[this.activity.entityType.key];
      if (!entityAutocompleteType) return [];
      const response = await fetch(
        `/easy_autocompletes/${entityAutocompleteType}?term=${searchTerm}`
      );
      let json = await response.json();
      const entities = json.entities || json.easy_contacts;
      return entities;
    },
    moveDate(date, time) {
      if (!date) {
        return moment(time).format("YYYY-MM-DD");
      }
      const newDate = moment(time);
      const momentDate = moment(date).date();
      newDate.date(momentDate);
      return moment(newDate).format("YYYY-MM-DD HH:mm");
    },
    multiselectChange(event, name) {
      const payload = {
        [name]: event.inputValue
      };
      this.$emit("save-value", { payload, name });
    }
  }
};
</script>

<style scoped></style>
