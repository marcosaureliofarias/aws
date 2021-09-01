<template>
  <section id="detail" :class="bem.ify(bem.block, 'section')">
    <ul :class="bem.ify(bem.block, 'attributes')">
      <Attribute :id="id" :bem="bem" :data="activity_type" />
      <div class="vue-modal__attribute activity-attribute">
        <Attribute
          :id="id"
          :bem="bem"
          :data="entity"
          @child-value-change="saveValue($event, 'entity_id')"
        />
        <div class="activity-attribute-with-button__button-wrapper">
          <a
            :href="entity.link"
            target="_blank"
            class="button"
            :title="translations.button_show_details"
          >
            {{ translations.button_show_details }}
          </a>
        </div>
      </div>
      <Attribute
        :id="id"
        :bem="bem"
        :data="date"
        @child-value-change="changeRange($event, 'date')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="startDate"
        @child-value-change="changeRange($event)"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="allDay"
        @child-value-change="saveValue($event, 'all_day')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="isFinished"
        @child-value-change="saveValue($event, 'is_finished')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="category"
        @child-value-change="saveValue($event, 'category_id')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :multiple="true"
        :data="users"
        @child-value-change="multiselectChange($event, 'principal')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :multiple="true"
        :data="contacts"
        @child-value-change="multiselectChange($event, 'contact')"
      />
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";

export default {
  name: "Detail",
  components: { Attribute },
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
    return {};
  },
  computed: {
    activity() {
      return this.$props.data;
    },
    activity_type() {
      return {
        labelName: this.translations.field_type,
        value: this.activity.entityType,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "easy_activity",
        optionsArray: this.activity.availableTypes,
        filterable: false,
        withSpan: false,
        editable: false
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
        editable: true
      };
    },
    entity() {
      const links = {
        "EasyCrmCase": `easy_crm_cases`,
        "EasyContact": `easy_contacts`,
        "EasyPersonalContact": `easy_personal_contacts`,
        "EasyPartner": `easy_partners`,
        "EasyLead": `easy_leads`
      };
      const link = `${window.urlPrefix}/${links[this.activity.entityType.key]}/${this.activity.entityId}`;
      return {
        labelName: this.activity.entityType.value,
        value: this.activity.entityName,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        attribute: "entity_id",
        searchQuery: this.fetchEntyties,
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: true,
        link
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
        editable: true
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
        editable: true
      };
    },
    users() {
      return {
        labelName: this.translations.label_user_plural,
        value: this.activity.userAttendees,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        placeholder: "---",
        inputType: "autocomplete",
        attribute: "principal",
        searchQuery: this.fetchUsers,
        optionsArray: false,
        withSpan: false,
        editable: true
      };
    },
    contacts() {
      return {
        labelName: this.translations.label_easy_contacts,
        value: this.activity.contactAttendees,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        placeholder: "---",
        inputType: "autocomplete",
        attribute: "contact",
        searchQuery: this.fetchContacts,
        optionsArray: false,
        withSpan: false,
        editable: true
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
        attribute: "approval_status",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: false
      };
    },
    date() {
      return {
        labelName: this.translations.label_date,
        placeholder: "---",
        date: this.activity.startTime,
        inputType: "date",
        attribute: "date",
        optionsArray: false,
        withSpan: false,
        editable: true
      };
    },
    startDate() {
      return {
        labelName: `${this.translations.label_date_from} -> ${this.translations.label_date_to}`,
        date: [this.activity.startTime, this.activity.endTime],
        placeholder: "---",
        inputType: "time",
        attribute: ["start_date", "due_date"],
        optionsArray: false,
        withSpan: false,
        editable: true,
        range: true,
        disabled: this.allDay.value
      };
    }
  },
  methods: {
    saveValue(payload, name) {
      this.$emit("save-value", { name, payload });
    },
    changeRange(payload, name) {
      const date = payload.inputValue;
      const start = this.activity.startTime;
      const end = this.activity.endTime;
      const activityDate = moment(start).format("YYYY-MM-DD");
      let attributes = {};
      if (this.allDay.value || name === "date") {
        attributes = {
          start_time: this.moveDate(date, start),
          end_time: this.moveDate(date, end)
        };
      } else {
        attributes = {
          start_time: `${moment(activityDate).format("YYYY-MM-DD")} ${date[0]}`,
          end_time: `${moment(activityDate).format("YYYY-MM-DD")} ${date[1]}`
        };
      }
      this.$emit("change-range", { attributes, payload });
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
      const entities = json.entities || json.contacts;
      return entities;
    },
    multiselectChange(event, name) {
      const payload = {
        [name]: this.getArrayOf("id", event.inputValue),
        showFlashMessage: event.showFlashMessage,
        changeSelectedValue: event.changeSelectedValue
      };
      this.$emit("save-value", { payload });
    }
  }
};
</script>

<style scoped></style>
