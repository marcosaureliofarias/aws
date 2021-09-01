<template>
  <div>
    <div
      class="vue-modal__form-step"
      :class="{ 'vue-modal__form-step--active': !showDateInput }"
    >
      <Attribute
        :id="null"
        :bem="bem"
        :data="taskInput"
        :required="true"
        class="vue-modal__attribute--long"
        @child-value-change="saveValues($event, 'task')"
      />
    </div>
    <transition name="slide-fade">
      <div
        class="vue-modal__form-step"
        :class="{
          'vue-modal__form-step--active': showDateInput && !showTimeInput
        }"
      >
        <Attribute
          v-if="showDateInput"
          :id="null"
          :bem="bem"
          :data="dateInput"
          :required="true"
          class="vue-modal__attribute--long"
          @child-value-change="saveValues($event, 'date')"
        />
      </div>
    </transition>
    <transition name="slide-fade">
      <div
        class="vue-modal__form-step"
        :class="{ 'vue-modal__form-step--active': showTimeInput }"
      >
        <Attribute
          v-if="showTimeInput"
          :id="null"
          :bem="bem"
          :data="timeInput"
          :required="true"
          class="vue-modal__attribute--long"
          @child-value-change="saveValues($event, 'time')"
        />
      </div>
    </transition>
    <Notification
      v-show="showErrors"
      :bem="bem"
      type="error"
      class="vue-modal__notification--beforeSubmit"
    >
      <ul style="list-style: none;">
        <li v-for="(error, i) in newAllocation.errorsList" :key="i">
          {{ error }}
        </li>
      </ul>
    </Notification>
  </div>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import allocationValidate from "../../graphql/mutations/allocationValidate";
import Notification from "../generalComponents/Notification";

export default {
  name: "NewAllocationContent",
  components: { Attribute, Notification },
  props: {
    bem: Object,
    newAllocation: Object,
    showErrors: Boolean
  },
  computed: {
    taskInput() {
      return {
        labelName: "task",
        value: this.$props.newAllocation.issue
          ? this.$props.newAllocation.issue.subject
          : "",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: false,
        filterable: false,
        firstOptionEmpty: true,
        searchQuery: this.fetchTask,
        withSpan: false,
        withLoading: false,
        editable: true
      };
    },
    dateInput() {
      return {
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName: "date",
        placeholder: "---",
        date: this.$props.newAllocation.date,
        inputType: "date",
        optionsArray: false,
        withSpan: false,
        editable: true,
        withLoading: false,
        disabled: false
      };
    },
    timeInput() {
      return {
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        labelName: "start -> end",
        placeholder: "",
        date: [this.startTime, this.endTime],
        inputType: "time",
        range: true,
        optionsArray: false,
        withSpan: false,
        editable: true,
        withLoading: false,
        disabled: false
      };
    },
    showDateInput() {
      return (
        this.$props.newAllocation.issue !== null &&
        this.$props.newAllocation.issue.id !== ""
      );
    },
    showTimeInput() {
      return (
        this.$props.newAllocation.date !== null &&
        this.$props.newAllocation.date !== "" &&
        this.showDateInput
      );
    },
    startTime() {
      return this.parseTimeForTimePicker(this.$props.newAllocation.startTime);
    },
    endTime() {
      return this.parseTimeForTimePicker(this.$props.newAllocation.endTime);
    }
  },
  methods: {
    async fetchTask(id, term) {
      const search = term || "";
      const url = `/easy_autocompletes/easy_scheduler_issues?user_id=${EASY.currentUser.id}&term=${search}`;
      const request = await fetch(url);
      const data = await request.json();
      return data.entities;
    },
    async saveValues(data, type) {
      const payload = {
        hours: this.$props.newAllocation.hours,
        start: this.$props.newAllocation.startTime,
        date: this.$props.newAllocation.date,
        user_id: this.$store.state.user.id,
        issue_id: this.$props.newAllocation.issue
          ? this.$props.newAllocation.issue.id
          : null
      };
      const saver = {};
      if (type === "time") {
        let start = data.inputValue[0];
        let end = data.inputValue[1];
        let hours = null;
        if (start !== "" || end !== "") {
          const startDuration = moment.duration(start);
          const endDuration = moment.duration(end);
          const diffInMilliseconds = endDuration - startDuration;
          const diff = moment.duration(diffInMilliseconds);
          hours = `${diff._data.hours}.${(diff._data.minutes / 60) * 100}`;
        } else {
          start = null;
          end = null;
        }
        payload.hours = hours;
        payload.start = start;
        saver.endTime = end;
        saver.hours = hours;
        saver.startTime = start;
      }
      if (type === "date") {
        let valueDate = null;
        if (data.inputValue !== "") {
          valueDate = data.inputValue;
        }
        payload.date = valueDate;
        saver.date = valueDate;
      }
      if (type === "task") {
        let taskData = null;
        payload.issue_id = null;
        if (data.inputValue.id !== "") {
          taskData = {
            id: data.inputValue.id,
            subject: data.inputValue.value
          };
          payload.issue_id = data.inputValue.id;
        }
        saver.issue = taskData;
      }
      const mutationPayload = {
        mutationName: "easyGanttResourceValidator",
        apolloMutation: {
          mutation: allocationValidate,
          variables: {
            attributes: payload
          }
        }
      };
      const response = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      const easyGanttResource = response.data.easyGanttResourceValidator;
      const errors = easyGanttResource.errors;
      let errorsList = [];
      if (errors.length) {
        errors.forEach(val => {
          val.fullMessages.forEach(mess => {
            errorsList.push(mess);
          });
        });
      }
      saver.errorsList = errorsList;
      const value = { ...this.$store.state.newEasyGanttResource, ...saver };
      const options = {
        name: "newEasyGanttResource",
        value: value,
        level: "state"
      };
      await this.$store.commit("setStoreValue", options);
    }
  }
};
</script>

<style scoped></style>
