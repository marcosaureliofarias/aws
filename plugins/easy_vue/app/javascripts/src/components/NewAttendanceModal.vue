<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="wrapper"
    :class="`${bem.block}--no-sidebar`"
    :block="bem.block"
    modificator="new"
    :previous-path-name="previousPathName"
    :previous-search="previousSearch"
    :on-close-fnc="onModalClose"
    :options="{ customStyles: 'max-width: 480px;' }"
  >
    <template slot="headline">
      <h2 class="vue-modal__headline ">
        <NewEntitySelect
          :bem="bem"
          :entity="entity"
          :translations="translations"
          @entity:changed="$emit('entity:changed', $event)"
        />
      </h2>
    </template>
    <template slot="body">
      <transition>
        <Notification v-if="$store.state.notification" :bem="bem" />
      </transition>
      <NewAttendanceDetail
        :bem="bem"
        :data="newAttendance"
        :translations="translations"
        :is-mobile="isMobile"
        :block="bem.block"
        @save-value="save($event)"
        @change-range="changeRange"
        @change-timerange="changeTimeRange"
        @description:changed="descriptionChanged($event)"
      />
    </template>
    <template slot="button-panel">
      <div class="vue-modal__button-panel">
        <button
          :class="buttonClass"
          :disabled="!showSave"
          @click="createAttendance"
        >
          {{ translations.button_create }}
        </button>
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import NewAttendanceDetail from "../components/attendance/NewAttendanceDetail";
import Notification from "../components/generalComponents/Notification";
import NewEntitySelect from "../components/NewEntitySelect";

import attendanceLocales from "../graphql/locales/attendance";
import attendanceSettings from "../graphql/attendanceSettings";
import attendanceInit from "../graphql/mutations/newAttendanceInit";
import attendanceValidate from "../graphql/mutations/attendanceValidate";
import attendanceCreate from "../graphql/mutations/attendanceCreate";
import issueHelper from "../store/actionHelpers";

export default {
  name: "NewAttendanceModal",
  components: {
    ModalWrapper,
    NewAttendanceDetail,
    Notification,
    NewEntitySelect
  },
  props: {
    actionButtons: {
      type: Array,
      default() {
        return [];
      }
    },
    isMobile: {
      type: Boolean,
      default: false
    },
    options: {
      type: Object,
      default: () => {}
    },
    bemBlock: String,
    entity: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    },
    currentUser: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      bem: {
        block: this.$props.bemBlock,
        ify: function(b, e, m) {
          let output = b;
          output += e ? "__" + e : "";
          output = m ? output + " " + output + "--" + m : output;
          return output.toLowerCase();
        }
      },
      previousPathName: "",
      previousSearch: "",
      errors: []
    };
  },
  computed: {
    newAttendance() {
      return this.$store.state.easyAttendance;
    },
    showSave() {
      const user = this.newAttendance.user;
      const activity = this.newAttendance.easyAttendanceActivity;
      if (!activity || !user || !user.length || (this.errors && this.errors.length))
        return false;
      return true;
    },
    buttonClass() {
      return {
        "button": !this.showSave,
        "button-positive": this.showSave
      };
    }
  },
  async created() {
    await this.init();
  },
  methods: {
    async init() {
      const store = this.$store;
      await this.setInitialState(store);
      await this.getLocales(store);
      await this.fetchSettings();
      await this.validateSchema(store);
      await this.$set(this.$store.state, "easyAttendance", {
        arrival: this.options.range ? this.options.range.start : null,
        departure: this.options.range ? this.options.range.end : null,
        description: "",
        user: [this.currentUser],
        easyAttendanceActivity: {},
        range: null,
        repeat: false,
        repeatDate: this.options.range ? this.options.range.start : null
      });
      await this.fetchAttendanceData(store);
      this.$store.state.showModal = true;
      document.body.classList.add("vueModalOpened");
    },
    onModalClose() {
      const evt = new CustomEvent("entityCreated", {
        cancelable: false,
        detail: { issue: this.$props.id }
      });
      document.dispatchEvent(evt);
      this.$store.replaceState(this.$store.state.initialState);
    },
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: attendanceSettings
        },
        processFunc(array) {
          return issueHelper.transformArrayToObject(array);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async getLocales(store) {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: attendanceLocales
        },
        processFunc(data) {
          return issueHelper.getLocales(data);
        }
      };
      await store.dispatch("fetchStateValue", payload);
    },
    async fetchAttendanceData(store) {
      const mutationPayload = {
        mutationName: "easyAttendanceValidator",
        apolloMutation: {
          mutation: attendanceInit,
          variables: {
            attributes: {}
          }
        },
        noNotification: true,
        noSuccessNotification: true
      };
      const { data } = await store.dispatch("mutateValue", mutationPayload);
      this.updateAttendance(data);
    },
    async createAttendance() {
      const attributes = this.getAttributes();
      const mutationPayload = {
        mutationName: "easyAttendanceCreate",
        apolloMutation: {
          mutation: attendanceCreate,
          variables: {
            attributes,
            userIds: this.getArrayOf("id", this.newAttendance.user)
          }
        }
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      const { errors } = data.easyAttendanceCreate;
      if (!errors || !errors.length) this.$refs.wrapper.closeModal();
      this.notify(errors);
    },
    getAttributes() {
      const attributes = {
        easy_attendance_activity_id: this.newAttendance.easyAttendanceActivity
          .id,
        description: this.newAttendance.description
      };
      this.addConditionalFields(attributes);
      return attributes;
    },
    async save(event) {
      const validateWhen = ["easyAttendanceActivity", "repeat", "repeatDate"];
      const { name, payload } = event;
      const { inputValue } = payload;
      this.setAttendance(inputValue, name);
      const validate = validateWhen.find((el) => name === el);
      if (validate) {
        const attendance = this.getAttributes();
        await this.attendanceValidate(attendance);
      }
    },
    async descriptionChanged(description) {
      const event = {
        name: "description",
        payload: { inputValue: description }
      };
      await this.save(event);
    },
    async attendanceValidate(attendance) {
      const mutationPayload = {
        mutationName: "easyAttendanceValidator",
        apolloMutation: {
          mutation: attendanceValidate,
          variables: {
            attributes: attendance,
            userIds: this.getArrayOf("id", this.newAttendance.user)
          }
        },
        noSuccessNotification: true
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateAttendance(data);
    },
    updateAttendance(data) {
      let { easyAttendance, errors } = data.easyAttendanceValidator;
      this.errors = errors;
      if (errors && errors.length) {
        this.notify(errors);
        return;
      }
      const attendance = this.$store.state.easyAttendance;
      easyAttendance = { ...attendance, ...easyAttendance };
      const options = {
        value: easyAttendance,
        name: "easyAttendance",
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
    },
    async changeRange(event) {
      const { attributes } = event;
      Object.entries(attributes).forEach((attr) => {
        const name = attr[1];
        const value = attr[0];
        this.setAttendance(name, value);
      });
      const attendance = this.getAttributes();
      await this.attendanceValidate(attendance);
    },
    async changeTimeRange(event) {
      const { attributes } = event;
      Object.entries(attributes).forEach((attr) => {
        const name = attr[1];
        const value = attr[0];
        this.setAttendance(name, value);
      });
      const attendance = this.getAttributes();
      await this.attendanceValidate(attendance);
    },
    addConditionalFields(attributes) {
      const attendance = this.newAttendance;
      const range = attendance.range;
      const start = moment(attendance.arrival).format("YYYY-MM-DD");
      if (range) {
        const time = attendance.non_work_start_time;
        const end = moment(attendance.departure).format("YYYY-MM-DD");
        attributes.arrival = { date: start };
        attributes.departure = { date: end };
        attributes.non_work_start_time = time;
        attributes.range = range.key;
        if (range.key === "3") {
          delete attributes.non_working_start_time;
        }
        return;
      }
      attributes.arrival = {
        time: moment(attendance.arrival).format("HH:mm")
      };
      attributes.departure = {
        time: moment(attendance.departure).format("HH:mm")
      };
      if (attendance.repeat) attributes.departure.date = attendance.repeatDate;
      attributes.attendance_date = start;
      return;
    },
    setAttendance(value, name) {
      const payload = {
        value,
        level: ["easyAttendance", name]
      };
      this.$store.commit("setStoreValue", payload);
    },
    async notify(errors) {
      await this.$store.commit("setNotification", { errors });
    }
  }
};
</script>

<style scoped></style>
