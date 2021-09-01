<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="wrapper"
    :class="`${block}--no-sidebar`"
    :block="block"
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
      <NewActivityDetail
        :bem="bem"
        :data="newActivity"
        :translations="translations"
        :is-mobile="isMobile"
        :block="block"
        @save-value="save($event)"
        @change-range="changeRange($event)"
        @description:changed="descriptionChanged($event)"
      />
    </template>
    <template slot="button-panel">
      <div class="vue-modal__button-panel">
        <button
          :class="buttonClass"
          :disabled="!showSave"
          @click="createActivity"
        >
          {{ translations.button_create }}
        </button>
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import NewActivityDetail from "../components/activity/NewActivityDetail";
import NewEntitySelect from "../components/NewEntitySelect";

import activityLocales from "../graphql/locales/activity";
import issueHelper from "../store/actionHelpers";
import activitySettings from "../graphql/activitySettings";
import activityCreate from "../graphql/mutations/activity";
import activityInit from "../graphql/mutations/newActivityInit";

export default {
  name: "NewSalesActivityModal",
  components: { ModalWrapper, NewActivityDetail, NewEntitySelect },
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
      block: this.$props.bemBlock,
      sidebarOpen: false,
      showErrors: false,
      previousPathName: "",
      previousSearch: ""
    };
  },
  computed: {
    newActivity() {
      return this.$store.state.easyEntityActivity;
    },
    showSave() {
      const entity = this.newActivity.entity;
      const start = this.newActivity.startTime;
      const end = this.newActivity.endTime;
      if (!entity.id || !start || !end) return false;
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
      this.setInitialState(store);
      await this.getLocales(store);
      await this.fetchSettings();
      await this.validateSchema(store);
      this.$set(this.$store.state, "easyEntityActivity", {
        allDay: false,
        description: "",
        category: {},
        endTime: this.options.range ?  this.options.range.end : new Date(),
        entity: {
          id: null,
          value: ""
        },
        entityType: {},
        isFinished: false,
        startTime: this.options.range ? this.options.range.start : new Date(),
        Principal: [this.currentUser.id],
        Contact: [],
        users: [
          {
            id: this.currentUser.id,
            name: this.currentUser.name
          }
        ]
      });
      await this.fetchActivityData(store);
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
          query: activitySettings
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
          query: activityLocales
        },
        processFunc(data) {
          return issueHelper.getLocales(data);
        }
      };
      await store.dispatch("fetchStateValue", payload);
    },
    async fetchActivityData(store) {
      const mutationPayload = {
        mutationName: "easyEntityActivityValidator",
        apolloMutation: {
          mutation: activityInit,
          variables: {
            attributes: {}
          }
        },
        noNotifications: true,
        noSuccessNotification: true
      };
      const { data } = await store.dispatch("mutateValue", mutationPayload);
      await this.updateActivity(data);
    },
    getAttributes() {
      const attributes = {
        entity_type: this.newActivity.entityType.key,
        entity_id: this.newActivity.entity.id,
        date: this.newActivity.startTime,
        start_time: this.newActivity.startTime,
        end_time: this.newActivity.endTime,
        all_day: this.newActivity.allDay,
        is_finished: this.newActivity.isFinished,
        category_id: this.newActivity.category.id,
        description: this.newActivity.description,
        Principal: this.newActivity.Principal,
        Contact: this.newActivity.Contact
      };
      return attributes;
    },
    async save(event) {
      const { name, payload } = event;
      const { inputValue, users, Contact } = payload;
      let value;
      if (name === "entityType") {
        this.clearEntity();
      }
      if (!inputValue) {
        value = users || Contact;
      } else {
        value = inputValue;
      }
      await this.setEasyActivity(value, name);
    },
    async descriptionChanged(description) {
      const event = {
        name: "description",
        payload: { inputValue: description }
      };
      await this.save(event);
    },
    async changeRange(event) {
      const { attributes } = event;
      Object.entries(attributes).forEach((attr) => {
        const name = attr[1];
        const value = attr[0];
        this.setEasyActivity(name, value);
      });
    },
    async createActivity() {
      const attributes = this.getAttributes();
      const attendees = {
        Principal: this.getArrayOf("id", this.newActivity.users),
        EasyContact: this.getArrayOf("id", this.newActivity.Contact)
      };
      const mutationPayload = {
        mutationName: "easyEntityActivity",
        apolloMutation: {
          mutation: activityCreate,
          variables: {
            id: null,
            attributes,
            attendees
          }
        },
        noNotifications: true,
        noSuccessNotification: true
      };
      await this.$store.dispatch("mutateValue", mutationPayload);
      this.$refs.wrapper.closeModal();
    },
    clearEntity() {
      const event = {
        name: "entity",
        payload: { inputValue: { id: null, value: "" } }
      };
      this.save(event);
    },
    setEasyActivity(value, name) {
      const payload = {
        value,
        level: ["easyEntityActivity", name]
      };
      this.$store.commit("setStoreValue", payload);
    },
    updateActivity(data) {
      let { easyEntityActivity } = data.easyEntityActivityValidator;
      const category = easyEntityActivity.categories.find((el) => el.isDefault);
      const entityType = easyEntityActivity.availableTypes[0];
      const activity = this.$store.state.easyEntityActivity;
      activity.category = category;
      activity.entityType = entityType;
      easyEntityActivity = { ...activity, ...easyEntityActivity };
      const options = {
        value: easyEntityActivity,
        name: "easyEntityActivity",
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
    }
  }
};
</script>

<style scoped></style>
