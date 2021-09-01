<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    ref="modal-wrapper"
    class="vue-modal--no-sidebar"
    :block="'vue-modal'"
    :on-close-fnc="onModalClose"
    :options="{ customStyles: 'height: auto; max-width: 480px' }"
  >
    <template slot="headline">
      <h2 :class="bem.ify(bem.block, 'headline') + ' color-scheme-modal '">
        Allocation
      </h2>
    </template>
    <AllocationContent
      :id="id"
      slot="body"
      :bem="bem"
      :translations="translations"
      :allocation="allocation"
    />
  </ModalWrapper>
</template>

<script>
import actionSubordinates from "../store/actionHelpers";
import { allSettingsQueryWithoutProject } from "../graphql/allSettings";
import locales from "../graphql/locales/issueProject";
import issueHelper from "../store/actionHelpers";
import ModalWrapper from "./generalComponents/Wrapper";
import AllocationContent from "./allocation/AllocationContent";
import { allocationQuery } from "../graphql/allocation.js";

export default {
  name: "AllocationModal",
  components: { ModalWrapper, AllocationContent },
  props: {
    id: {
      type: [String, Number]
    },
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
    bemBlock: String,
    options: {
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
      subject: ""
    };
  },
  computed: {
    translations() {
      return this.$store.state.allLocales;
    },
    allocation() {
      return this.$store.state.easyGanttResource;
    }
  },
  created() {
    this.$set(this.$store.state, "easyGanttResource", {});
    this.init();
  },
  methods: {
    async init() {
      const store = this.$store;
      this.setInitialState(store);
      // fetch data
      await this.validateSchema(store);
      await this.getAllocation(store);
      await this.getLocales(store);
      await this.fetchSettings(store);
      this.easyGanttResource = await store.state.easyGanttResource;
      // open modal
      this.openModal();
      document.body.classList.add("vueModalOpened");
      document.addEventListener("keyup", this.closeOnEscape);
    },
    async getAllocation(store) {
      const payload = {
        name: "easyGanttResource",
        apolloQuery: {
          query: allocationQuery,
          variables: {
            id: this.id
          }
        }
      };
      await store.dispatch("fetchStateValue", payload);
    },
    async getLocales(store) {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: locales
        },
        processFunc(data) {
          return actionSubordinates.getLocales(data);
        }
      };
      await store.dispatch("fetchStateValue", payload);
    },
    async fetchSettings() {
      const payload = {
        name: "allSettings",
        apolloQuery: {
          query: allSettingsQueryWithoutProject,
          variables: {
            id: this.$props.id
          }
        },
        processFunc(array) {
          return issueHelper.transformArrayToObject(array);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    openModal() {
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state"
      };
      this.$store.commit("setStoreValue", payloadShow);
      const evt = new CustomEvent("vueModalAllocationOpened", {
        cancelable: false
      });
      document.dispatchEvent(evt);
    },
    onModalClose() {
      const evt = new CustomEvent("vueModalIssueChanged", {
        cancelable: false,
        detail: { project: this.$props.id }
      });
      document.dispatchEvent(evt);
    }
  }
};
</script>
<style scoped></style>
