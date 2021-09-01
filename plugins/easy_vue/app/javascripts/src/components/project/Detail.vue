<template>
  <section id="detail" :class="bem.ify(block, 'section')">
    <ul :class="bem.ify(block, 'attributes')">
      <Attribute
        :id="+project.id"
        :bem="bem"
        :data="authorInput"
        @child-value-change="saveValue($event, 'author_id', 'author')"
      />
      <Attribute
        :id="+project.id"
        :bem="bem"
        :data="startDateInput"
        @child-value-change="
          saveValue($event, 'start_date', 'startDate', getValue)
        "
      />
      <Attribute
        :id="+project.id"
        :bem="bem"
        :data="dueDateInput"
        @child-value-change="saveValue($event, 'due_date', 'dueDate', getValue)"
      />
      <Attribute :id="+project.id" :bem="bem" :data="estimatedHoursInput" />
      <Attribute :id="+project.id" :bem="bem" :data="spentHoursInput" />
      <Attribute :id="+project.id" :bem="bem" :data="createdInput" />
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import actionSubordinates from "../../store/actionHelpers";

export default {
  name: "Detail",
  components: {
    Attribute
  },
  props: { project: Object, bem: Object },
  data() {
    return {
      statuses: [],
      assignees: [],
      createdDate: this.dateFormat(this.$props.project.createdOn),
      priorities: [],
      sprints: [],
      milestones: [],
      componentOrder: [],
      getPriority: actionSubordinates.getPriority,
      authorInput: {
        labelName: this.$store.state.allLocales.field_author,
        value: this.$props.project ? this.$props.project.author.name : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        id: "#author-input-select",
        inputType: "select",
        optionsArray: [],
        withSpan: false,
        editable: false
      },
      startDateInput: {
        labelName: this.$store.state.allLocales.field_start_date,
        placeholder: "---",
        date: this.$props.project.startDate,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "date",
        optionsArray: false,
        withSpan: false,
        editable: false
      },
      dueDateInput: {
        labelName: this.$store.state.allLocales.field_due_date,
        placeholder: "---",
        date: this.$props.project.dueDate,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "date",
        optionsArray: false,
        withSpan: false,
        editable: false
      },
      spentHoursInput: {
        labelName: this.$store.state.allLocales.label_spent_time,
        placeholder: "---",
        date: this.$props.project.totalSpentHours,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "int",
        optionsArray: [],
        withSpan: false,
        editable: false
      },
      estimatedHoursInput: {
        labelName: this.$store.state.allLocales.field_estimated_hours,
        placeholder: "---",
        date: this.$props.project.totalEstimatedHours,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "int",
        optionsArray: [],
        withSpan: false,
        editable: false
      },
      createdInput: {
        labelName: this.$store.state.allLocales.field_created_on,
        value: this.dateFormat(this.$props.project.createdOn),
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "select",
        optionsArray: [],
        withSpan: false,
        editable: false
      },
      block: this.$props.bem.block,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase()
    };
  },
  methods: {
    getValue(eventValue) {
      return eventValue.inputValue.value || eventValue.inputValue;
    }
  }
};
</script>

<style scoped></style>
