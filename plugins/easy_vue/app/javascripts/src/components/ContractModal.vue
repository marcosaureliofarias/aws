<template>
  <ModalWrapper
    v-if="$store.state.showModal"
    :block="block"
    :previous-path-name="previousPathName"
    :previous-search="previousSearch"
  >
    <template slot="headline">
      <h2 class="vue-modal__headline ">
        <a :href="easyContract.account.easyContactPath" target="_blank">{{
          easyContract.account.name
        }}</a>
      </h2>
    </template>
    <template slot="body">
      <Detail
        :id="id"
        :bem="bem"
        :easy-contract="easyContract"
        :translations="translations"
      />
      <CrmCases
        :bem="bem"
        :crm-cases="easyContract.easyCrmCases"
        :block="block"
        :translations="translations"
      />
      <Invoices
        :bem="bem"
        :invoices="easyContract.easyInvoices"
        :block="block"
        :translations="translations"
      />
    </template>
    <Sidebar
      slot="sidebar"
      :active="buttons"
      :actions="actionButtons"
      :reference="`#${id}`"
      :bem="bem"
    />
  </ModalWrapper>
</template>

<script>
import ModalWrapper from "./generalComponents/Wrapper";
import Sidebar from "./generalComponents/Sidebar";
import actionSubordinates from "../store/actionHelpers";
import { contractQuery } from "../graphql/contract";
import locales from "../graphql/locales/contract";
import Detail from "./contract/Detail";
import CrmCases from "./contract/CrmCases";
import Invoices from "./contract/Invoices";

export default {
  name: "ContractModal",
  components: { Invoices, CrmCases, Detail, Sidebar, ModalWrapper },
  props: {
    id: [String, Number],
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
      previousPathName: "",
      previousSearch: "",
      block: this.$props.bemBlock
    };
  },
  computed: {
    easyContract() {
      return this.$store.state.easyContract;
    },
    buttons() {
      return [
        {
          name: this.translations.label_details,
          anchor: "#detail",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.translations.label_easy_contact_easy_crm_cases,
          anchor: "#crmCases",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.translations.label_easy_invoice_plural,
          anchor: "#invoices",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        }
      ];
    },
    translations() {
      return this.$store.state.allLocales;
    }
  },
  created() {
    this.$set(this.$store.state, "easyContract", {});
    this.openModal();
  },
  methods: {
    async openModal() {
      await this.getLocales();
      await this.fetchContractData();
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state"
      };
      this.$store.commit("setStoreValue", payloadShow);
    },
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: locales
        },
        processFunc(data) {
          return actionSubordinates.getLocales(data);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchContractData() {
      // Fetch and set contract data
      const payload = {
        name: "easyContract",
        apolloQuery: {
          query: contractQuery,
          variables: { id: this.$props.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    }
  }
};
</script>

<style scoped></style>
