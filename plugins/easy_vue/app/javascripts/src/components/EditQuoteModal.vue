<template>
  <FormModalWrapper
    ref="modal"
    class="vue-modal"
    :title="translations.quote_form_edit_quote_header"
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
        {{ translations.form_modal_label_submit_edit_form_button }}
      </a-button>
    </template>
  </FormModalWrapper>
</template>

<script>
import quoteLocales from "../graphql/locales/quote";
import { quoteQuery } from "../graphql/quote";
import actionHelpers from "../store/actionHelpers";
import FormModalWrapper from "./FormModalWrapper";
import QuoteForm from "./QuoteForm";
import QuoteUpdate from "../plugins/quoteUpdate.js";

export default {
  name: "EditQuoteModal",
  components: {
    FormModalWrapper,
    QuoteForm
  },
  props: {
    id: {
      type: [String, Number]
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
    quote() {
      return this.$store.state.easyPriceBookQuote;
    }
  },
  methods: {
    async init() {
      const store = this.$store;
      this.setInitialState(store);
      this.modalLoading = true;
      // fetch data
      await this.fetchQuoteData();
      await Promise.all([
        this.fetchAvailableVariables(),
        this.getLocales()
      ]);
      this.mapDefaultData();
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
    async fetchQuoteData() {
      const payload = {
        name: "easyPriceBookQuote",
        apolloQuery: {
          query: quoteQuery,
          variables: { id: this.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchAvailableVariables() {
      const id = this.quote.easyCrmCase?.id;
      this.availableVariables = await this.getAvailableVariables(id);
    },
    mapDefaultData() {
        this.form = {
            brand_id: this.quote.brand.id,
            subscription_type: this.quote.subscriptionType,
            easy_crm_case_id: this.quote.easyCrmCase.id,
            start_date: this.quote.startDate,
            currency: this.quote.currency,
            due_date: this.quote.dueDate,
            userlimit: this.quote.userlimit,
            usermonths: this.quote.usermonths,
            solution: this.quote.solution,
            name: this.quote.name
        };
    },
    async submit() {
      if (!this.validate("quote")) {
        return;
      }
      this.submitLoading = true;
      const Fetcher = new QuoteUpdate(this.form, this.id);
      const result = await Fetcher.update();
      if (result) {
        location.reload();
      }
      this.$refs.modal.closeModal();
      this.submitLoading = false;
    }
  }
};
</script>