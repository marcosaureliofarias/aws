<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="wrapper"
    :modificator="`sales-activity`"
    :block="block"
    :no-sidebar="true"
    :class="`${bem.block}--no-sidebar`"
    :on-close-fnc="dispatchModalChange"
  >
    <template slot="headline">
      <h2 :class="bem.ify(bem.block, 'headline')">
        {{ translations.easy_scheduler_label_sales_activity }}
      </h2>
    </template>
    <template slot="body">
      <Detail
        :bem="bem"
        :data="activity"
        :translations="translations"
        :is-mobile="isMobile"
        :block="block"
        @save-value="save($event)"
        @change-range="changeRange($event)"
      />
      <Description
        :bem="bem"
        :editable="true"
        :textile="textile"
        :entity="activity"
        @save="saveDescription($event)"
      />
    </template>
    <template slot="button-panel">
      <div class="vue-modal__button-panel">
        <span
          v-for="(button, i) in buttons"
          :key="i"
          style="margin: 0.4rem 0.2rem"
        >
          <button
            v-if="button.show"
            :class="`${button.class} excluded`"
            :disabled="button.disabled"
            @click="button.func($event)"
          >
            {{ button.name }}
          </button>
        </span>
        <PopUp
          v-if="currentComponent"
          :bem="bem"
          :align="alignment"
          :component="currentComponent"
          :custom-styles="custom"
          :options="popUpOptions"
          :translations="translations"
          @onBlur="closePopUp"
          @confirmed="confirmAction"
        />
      </div>
    </template>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import Detail from "./activity/Detail";
import Description from "./generalComponents/Description";
import PopUp from "./generalComponents/PopUp";
import { activityQuery } from "../graphql/activity";
import activityLocales from "../graphql/locales/activity";
import actionSubordinates from "../store/actionHelpers";
import activitySettings from "../graphql/activitySettings";
import mutation from "../graphql/mutations/activity";

export default {
  name: "SalesActivityModal",
  components: { ModalWrapper, Detail, Description, PopUp },
  props: {
    id: {
      type: [String, Number]
    },
    isMobile: {
      type: Boolean,
      default: false
    },
    bemBlock: String
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
      custom: {},
      allignement: {},
      currentComponent: "",
      popUpOptions: {},
      action: {},
      locales: this.$store.state.allLocales,
      block: this.$props.bemBlock,
      actions: this.$props.actionButtons
    };
  },
  computed: {
    activity() {
      return this.$store.state.easyEntityActivity;
    },
    translations() {
      return this.$store.state.allLocales;
    },
    textile() {
      if (!this.$store.state.allSettings) return false;
      return this.$store.state.allSettings.text_formatting !== "HTML";
    },
    buttons() {
      return [
        {
          name: this.translations.button_delete,
          func: (e) => {
            this.deleteActivity(this.activity.id);
            this.showConfirm(e, this.$props.isMobile);
          },
          show: true,
          class: "button-negative",
          disabled: false
        },
        {
          name: this.translations.button_cancel,
          func: () => {
            this.$refs.wrapper.closeModal();
          },
          show: true,
          class: "button",
          disabled: false
        }
      ];
    }
  },
  async created() {
    this.$set(this.$store.state, "easyEntityActivity", {});
    await this.openModal();
  },
  methods: {
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: activityLocales
        },
        processFunc(data) {
          return actionSubordinates.getLocales(data);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async openModal() {
      await this.getLocales();
      await this.fetchSettings();
      await this.fetchActivityData();
      this.setIsMobile();
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state"
      };
      this.$store.commit("setStoreValue", payloadShow);
      const evt = new CustomEvent("vueModalIssueOpened", {
        cancelable: false,
        detail: { issue: this.$props.id }
      });
      document.dispatchEvent(evt);
    },
    setIsMobile() {
      const options = {
        name: "isMobile",
        value: ERUI.isMobile,
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
    },
    async fetchActivityData() {
      // Fetch and set activity data
      const payload = {
        name: "easyEntityActivity",
        apolloQuery: {
          query: activityQuery,
          variables: { id: this.$props.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: activitySettings
        },
        processFunc(array) {
          return actionSubordinates.transformArrayToObject(array);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async save(event) {
      const { name, payload } = event;
      let attributes;
      if (name) {
        attributes = {
          [name]:
            payload.inputValue.id ||
            payload.inputValue.key ||
            payload.inputValue
        };
      } else {
        attributes = {};
      }
      const attendees = {
        Principal:
          payload.principal ||
          this.getArrayOf("id", this.activity.userAttendees),
        EasyContact:
          payload.contact ||
          this.getArrayOf("id", this.activity.contactAttendees)
      };
      const mutationPayload = {
        mutationName: "easyEntityActivity",
        apolloMutation: {
          mutation: mutation,
          variables: {
            id: this.activity.id,
            attributes,
            attendees
          }
        },
        processFunc: payload.showFlashMessage ? payload.showFlashMessage : null
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateActivity(data);
    },
    async changeRange(event) {
      const { attributes, payload } = event;
      const attendees = {
        Principal: this.getArrayOf("id", this.activity.userAttendees),
        EasyContact: this.getArrayOf("id", this.activity.contactAttendees)
      };
      const mutationPayload = {
        mutationName: "easyEntityActivity",
        apolloMutation: {
          mutation: mutation,
          variables: {
            id: this.activity.id,
            attributes,
            attendees
          }
        },
        processFunc: payload.showFlashMessage ? payload.showFlashMessage : null
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateActivity(data);
    },
    async saveDescription(description) {
      const attributes = {
        description
      };
      const attendees = {
        Principal: this.getArrayOf("id", this.activity.userAttendees),
        EasyContact: this.getArrayOf("id", this.activity.contactAttendees)
      };
      const mutationPayload = {
        mutationName: "activityUpdate",
        apolloMutation: {
          mutation: mutation,
          variables: {
            id: this.activity.id,
            attributes,
            attendees
          }
        }
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      this.updateAttendance(data);
    },
    dispatchModalChange() {
      const evt = new CustomEvent("vueModalIssueChanged", {
        cancelable: false,
        detail: {
          id: this.$props.id
        }
      });
      document.dispatchEvent(evt);
    },
    confirm(e) {
      this.action.func = e.action;
      this.action.close = e.close;
      this.showConfirm(e.eventData, this.$props.isMobile);
    },
    showConfirm(e, isMobile, options) {
      const defaultOptions = {
        topOffs: -80,
        rightOffs: 325
      };
      const alligmentOptions = options ? options : defaultOptions;
      this.custom = {
        width: "auto",
        height: "95px !important",
        display: "flex",
        "align-items": "center"
      };
      this.alignment = this.getAlignment(e, alligmentOptions, isMobile);
      this.currentComponent = "Confirm";
    },
    confirmAction(confirmed) {
      if (confirmed) {
        this.action.func();
        if (this.action.close) this.$refs.wrapper.closeModal();
      }
      this.currentComponent = null;
    },
    closePopUp() {
      this.currentComponent = null;
    },
    updateActivity(data) {
      const { easyEntityActivity, errors } = data.easyEntityActivity;
      if (errors.length) return;
      const options = {
        value: easyEntityActivity,
        name: "easyEntityActivity",
        level: "state"
      };
      this.$store.commit("setStoreValue", options);
    },
    deleteActivity(id) {
      this.action.func = async () => {
        const req = new Request(`/easy_entity_activities/${id}.json`);
        const options = {
          method: "DELETE"
        };
        try {
          await fetch(req, options);
        } catch (err) {
          throw new Error(`Delete activity error: ${err}`);
        }
      };
      this.action.close = true;
    }
  }
};
</script>

<style scoped></style>
