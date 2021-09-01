<template>
  <section id="detail" :class="bem.ify(bem.block, 'section')">
    <ul :class="bem.ify(bem.block, 'attributes')">
      <Attribute
        :id="id"
        :bem="bem"
        :data="taskInput"
        @child-value-change="saveValues($event)"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="dateInput"
        @child-value-change="saveValues($event, 'date')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="timeInput"
        @child-value-change="saveValues($event, 'time')"
      />
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import allocation from "../../graphql/mutations/allocation";

export default {
  name: "AllocationContent",
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
    },
    allocation: {
      type: Object,
      default: () => {}
    }
  },
  computed: {
    taskInput() {
      return {
        labelName: this.translations.field_issue,
        value: this.$props.allocation.issue.subject,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        filterable: false,
        firstOptionEmpty: true,
        searchQuery: this.fetchTask,
        withSpan: false,
        editable: false
      };
    },
    dateInput() {
      return {
        labelName: "date",
        placeholder: "---",
        date: this.$props.allocation.date,
        inputType: "date",
        optionsArray: false,
        withSpan: false,
        editable: true,
        disabled: false
      };
    },
    timeInput() {
      return {
        labelName: "start -> end",
        placeholder: "",
        date: [
          this.$props.allocation.startTime,
          this.$props.allocation.endTime
        ],
        inputType: "time",
        range: true,
        optionsArray: false,
        withSpan: false,
        editable: true,
        disabled: false
      };
    }
  },
  methods: {
    async saveValues(data, type) {
      const payload = {};
      if (type === "time") {
        const start = data.inputValue[0];
        const end = data.inputValue[1];
        const startDuration = moment.duration(start);
        const endDuration = moment.duration(end);
        const diffInMilliseconds = endDuration - startDuration;
        const diff = moment.duration(diffInMilliseconds);
        const hours = `${diff._data.hours}.${(diff._data.minutes / 60) * 100}`;
        payload.hours = hours;
        payload.start = start;
      }
      if (type === "date") {
        payload.date = data.inputValue;
      }
      const mutationPayload = {
        mutationName: "easyGanttResource",
        apolloMutation: {
          mutation: allocation,
          variables: {
            id: this.$props.id,
            attributes: payload
          }
        },
        processFunc: data.showFlashMessage ? data.showFlashMessage : null
      };
      const response = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      const easyGanttResource = response.data.easyGanttResource;
      const reosourceDAta = easyGanttResource.easyGanttResource;
      const errors = easyGanttResource.errors;
      if (errors.length) return;
      const options = {
        name: "easyGanttResource",
        value: reosourceDAta,
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
    },
    async fetchTask(id, term) {
      const search = term || "";
      const url = `/easy_autocompletes/easy_scheduler_issues?user_id=${EASY.currentUser.id}&term=${search}`;
      const request = await fetch(url);
      const data = await request.json();
      return data.entities;
    }
  }
};
</script>

<style scoped></style>
