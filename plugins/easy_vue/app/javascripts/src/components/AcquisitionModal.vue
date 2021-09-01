<template>
  <FormModalWrapper
    ref="modal"
    class="vue-modal"
    :title="translations.acquisition_header"
    :loading="modalLoading"
    :skeleton-rows="skeletonLoadingSize"
    @onModalOpen="init"
  >
    <a-row :gutter="16">
      <a-col :offset="4" :md="7">
        <AcquisitionForm 
          :id="id"
          ref="acquisition"
          v-model="form" 
          :translations="translations" 
          :submit-loading="submitLoading"
          :ewa-instaces="ewaInstaces"
        />
      </a-col>
      <a-col
        :offset="2" 
        :md="8"
      >
        <ModalSummary v-if="!modalLoading" :form="form" :translations="translations" />
      </a-col>
    </a-row>
    <template slot="footer">
      <a-button key="submit" type="primary" :loading="submitLoading" @click="submit">
        {{ translations.form_modal_label_submit_form_button }}
      </a-button>
    </template>
  </FormModalWrapper>
</template>

<script>
import { acquisitionsQuery } from "../graphql/acquisitions";
import actionHelpers from "../store/actionHelpers";
import acquisitionsLocales from "../graphql/locales/acquisition";
import FormModalWrapper from "./FormModalWrapper";
import ModalSummary from "./acquisitions/ModalSummary";
import AcquisitionForm from "./acquisitions/AcquisitionForm";
import AcquisitionSubmit from "../plugins/acquisition.js";
import ModalFormFetcher from "../plugins/modalForm.js";

export default {
  name: "AcquisitionModal",
  components: {
    FormModalWrapper,
    ModalSummary,
    AcquisitionForm
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
      ewaSelectDisabled: false,
      skeletonLoadingSize: 10,
      form: {},
      ewaInstaces: []
    };
  },
  computed: {
    translations() {
      return this.$store.state.allLocales;
    },
    easyCrmCase() {
      return this.$store.state.easyCrmCase;
    }
  },
  created() {
    this.$set(this.$store.state, "easyAcquisition", {});
  },
  methods: {
    async init() {
      const store = this.$store;
      this.setInitialState(store);
      this.modalLoading = true;
      // fetch data
      await Promise.all([
        this.fetchAcquisitionData(),
        this.getLocales()
      ]);
      await this.fetchEwas();
      this.checkActiveQuote();
      this.processDefaultData();
      this.modalLoading = false;
    },
    async fetchAcquisitionData() {
      // Fetch and set attendance data
      const payload = {
        name: "easyCrmCase",
        apolloQuery: {
          query: acquisitionsQuery,
          variables: { id: this.id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: acquisitionsLocales
        },
        processFunc(data) {
          return actionHelpers.getLocales(data);
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    async fetchEwas() {
      if (this.easyCrmCase.activeQuote?.solution !== "cloud") return;
      const reqUrl = `/easy_autocompletes/available_easy_web_applications_for_easy_crm_case.json?
easy_crm_case_id=${this.id}`;
      const fetcher = new ModalFormFetcher(reqUrl);
      const data = await fetcher.fetch();
      this.ewaInstaces = data.entities;
    },
    checkActiveQuote() {
      if (!this.easyCrmCase || !this.easyCrmCase.activeQuote) {
        this.$refs.modal.closeModal();
        this.$notification["error"]({
          message: this.translations.form_modal_error_empty_quote_error_title,
          description: this.translations.form_modal_error_empty_quote_error_description,
        });
      }
    },
    processDefaultData() {
      if (this.easyCrmCase && this.easyCrmCase.activeQuote) {
        this.form = this.easyCrmCase.activeQuote;
      }
      if (this.easyCrmCase.easyWebApplication) {
        this.form.easyWebApplication = parseInt(this.easyCrmCase.easyWebApplication.id);
        this.ewaSelectDisabled = true;
      }
    },
    async submit() {
      if (!this.validate("acquisition")) {
        return;
      }
      this.submitLoading = true;
      const Fetcher = new AcquisitionSubmit(this.form, this.id);
      const result = await Fetcher.submit();
      if (result) {
        location.reload();
      }
      this.$refs.modal.closeModal();
      this.submitLoading = false;
    }
  }
};
</script>