<template>
  <FormModalWrapper
    ref="modal"
    class="vue-modal"
    :title="translations.quote_form_new_quote_header"
    :loading="modalLoading"
    :skeleton-rows="skeletonLoadingSize"
    @onModalOpen="init"
  >
    <QuoteForm
      ref="quote"
      :form="form"
      :translations="translations"
      :submit-loading="submitLoading"
      :available-variables="availableVariables"
    />
    <template slot="footer">
      <a-button key="submit" type="primary" :loading="submitLoading" @click="submit">
        {{ translations.form_modal_label_submit_form_button }}
      </a-button>
    </template>
  </FormModalWrapper>
</template>

<script>
import quoteLocales from "../graphql/locales/quote";
import { quotePefillQuery } from "../graphql/quotePefiill";
import actionHelpers from "../store/actionHelpers";
import FormModalWrapper from "./FormModalWrapper";
import QuoteForm from "./QuoteForm";
import QuoteSubmit from "../plugins/quoteSubmit.js";

export default {
  name: "NewQuoteModal",
  components: {
    FormModalWrapper,
    QuoteForm
  },
  props: {
    id: {
      type: [String, Number],
      default: ""
    }
  },
  data() {
    return {
      modalLoading: false,
      submitLoading: false,
      skeletonLoadingSize: 15,
      form: {},
      availableVariables: {}
    };
  },
  computed: {
    translations() {
      return this.$store.state.allLocales;
    },
    crm() {
      return this.$store.state.easyCrmCase || {};  
    }
  },
  methods: {
    async init() {
      const store = this.$store;
      this.setInitialState(store);
      this.modalLoading = true;
      // fetch data
      await Promise.all([
        this.fetchQuotePrefill(),
        this.fetchAvailableVariables(),
        this.getLocales()
      ]);
      this.prefillDefaultData();
      this.modalLoading = false;
    },
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: quoteLocales
        },
        processFunc(data) {
          return actionHelpers.getLocales(data);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchQuotePrefill() {
      const payload = {
        name: "easyCrmCase",
        apolloQuery: {
          query: quotePefillQuery,
          variables: { id: this.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchAvailableVariables() {
      this.availableVariables = await this.getAvailableVariables(this.id);
    },
    prefillDefaultData() {
      this.form = {
        usermonths: (this.crm.activeQuote && this.crm.activeQuote.usermonths) ? this.crm.activeQuote.usermonths : 12,
        userlimit: (this.crm.activeQuote && this.crm.activeQuote.userlimit) ? this.crm.activeQuote.userlimit : 10,
        brand_id: this.crm.activeQuote?.brand?.id,
        currency: this.crm.currency,
        solution: "cloud"
      };
      if (!this.crm.activeQuote) {
        this.form.active = true;
      }
    },
    async submit() {
      if (!this.validate("quote")) {
        return;
      }
      this.submitLoading = true;
      if (!this.form.easy_crm_case_id) {
        this.form.easy_crm_case_id = this.id;
      }
      const Fetcher = new QuoteSubmit(this.form);
      const result = await Fetcher.submit();
      if (result) {
        const newModalUrl = `${window.urlPrefix}/easy_crm_cases/${this.id}
          /items?easy_price_book_quote_id=${result.easy_price_book_quote.id}`;
        // I had problem to make same request with fetch() so I use exact ajax that is used on backend 
        $.ajax({
          type: "GET",
          url: newModalUrl,
          dataType: "script",
          success: (result) => {
            const script = new Function (result);
            script();
          }
        });
      }
      this.$refs.modal.closeModal();
      this.submitLoading = false;
    }
  }
};
</script>