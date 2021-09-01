<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="wrapper"
    :modificator="`sales-activity`"
    :block="block"
    :on-close-fnc="dispatchModalChange"
    :options="{ customStyles: 'height: auto;' }"
  >
    <template slot="headline">
      <h2 :class="bem.ify(bem.block, 'headline')">
        {{ $store.state.easyIcalendarEvent.summary }}
      </h2>
    </template>
    <template slot="body">
      <Detail
        :bem="bem"
        :data="$store.state.easyIcalendarEvent"
        :translations="translations"
        :is-mobile="isMobile"
        :block="block"
      />
    </template>
    <Sidebar
      slot="sidebar"
      :actions="sidebarButtons"
      :bem="bem"
      :is-mobile="isMobile"
      @confirm="confirm($event)"
    >
      <PopUp
        v-if="currentComponent"
        slot="popup"
        :bem="bem"
        :align="alignment"
        :component="currentComponent"
        :custom-styles="custom"
        :options="popUpOptions"
        :translations="translations"
        @onBlur="closePopUp"
        @confirmed="confirmAction"
      />
    </Sidebar>
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import Detail from "./externalEvent/Detail";
import Sidebar from "./generalComponents/Sidebar";
import PopUp from "./generalComponents/PopUp";
import { externalEventQuery } from "../graphql/externalEvent";
import externalEventLocales from "../graphql/locales/externalEvent";
import actionSubordinates from "../store/actionHelpers";
import externalEventSettings from "../graphql/externalEventSettings";

export default {
  name: "SalesActivityModal",
  components: { ModalWrapper, Detail, PopUp, Sidebar },
  props: {
    id: {
      type: [String, Number],
    },
    isMobile: {
      type: Boolean,
      default: false,
    },
    bemBlock: String,
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
        },
      },
      custom: {},
      allignement: {},
      currentComponent: "",
      popUpOptions: {},
      action: {},
      locales: this.$store.state.allLocales,
      block: this.$props.bemBlock,
      actions: this.$props.actionButtons,
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
    sidebarButtons() {
      return [
        {
          name: "Sync",
          enabled: true,
          func: async () => {
            const id = this.$store.state.easyIcalendarEvent.easyIcalendar.id;
            await this.syncEvent(id);
          }
        }
      ];
    },
  },
  async created() {
    this.$set(this.$store.state, "easyIcalendarEvent", {});
    await this.openModal();
  },
  methods: {
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: externalEventLocales,
        },
        processFunc(data) {
          return actionSubordinates.getLocales(data);
        },
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async openModal() {
      await this.getLocales();
      await this.fetchSettings();
      await this.fetchEventData();
      this.setIsMobile();
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state",
      };
      this.$store.commit("setStoreValue", payloadShow);
      const evt = new CustomEvent("vueModalIssueOpened", {
        cancelable: false,
        detail: { issue: this.$props.id },
      });
      document.dispatchEvent(evt);
    },
    setIsMobile() {
      const options = {
        name: "isMobile",
        value: ERUI.isMobile,
        level: "state",
      };
      this.$store.commit("setStoreValue", options);
    },
    async fetchEventData() {
      // Fetch and set activity data
      const payload = {
        name: "easyIcalendarEvent",
        apolloQuery: {
          query: externalEventQuery,
          variables: { id: this.$props.id },
        },
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: externalEventSettings,
        },
        processFunc(array) {
          return actionSubordinates.transformArrayToObject(array);
        },
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    confirm(e) {
      this.action.func = e.action;
      this.action.close = e.close;
      this.showConfirm(e.eventData, this.$props.isMobile);
    },
    showConfirm(e, isMobile, options) {
      const defaultOptions = {
        topOffs: 10,
      };
      const alligmentOptions = options ? options : defaultOptions;
      this.custom = {
        width: "auto",
        height: "95px !important",
        display: "flex",
        "align-items": "center",
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
    deleteActivity(id) {
      this.action.func = async () => {
        const req = new Request(`/easy_entity_activities/${id}.json`);
        const options = {
          method: "DELETE",
        };
        try {
          await fetch(req, options);
        } catch (err) {
          throw new Error(`Delete activity error: ${err}`);
        }
      };
      this.action.close = true;
    },
    dispatchModalChange() {
      const evt = new CustomEvent("vueModalIssueChanged", {
        cancelable: false,
        detail: {
          id: this.$props.id,
        },
      });
      document.dispatchEvent(evt);
    },
    async syncEvent(id) {
      const url = `${window.urlPrefix}/easy_icalendars/${id}/sync`;
      const req = new Request(url);
      await fetch(req);
    }
  },
};
</script>

<style scoped></style>
