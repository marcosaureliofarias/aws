<template>
  <a-form-model 
    ref="quote" 
    :model="form"
    layout="horizontal" 
    :rules="rules" 
  >
    <a-row :gutter="16">
      <a-col :offset="4" :md="7">
        <a-form-model-item :label="translations.quote_form_label_name" prop="name">
          <a-input v-model="form.name" :disabled="submitLoading" />
        </a-form-model-item>
        <a-form-model-item :label="translations.quote_form_label_currency" prop="currency">
          <a-select
            v-model="form.currency"
            :default-value="form.currency"
            :disabled="submitLoading"
            :placeholder="translations.quote_form_placeholder_currency"
          >
            <a-select-option v-for="(currency, i) in currencies" :key="i" :value="currency.isoCode">
              {{ currency.name }}
            </a-select-option>
          </a-select>
        </a-form-model-item>
        <a-form-model-item :label="translations.quote_form_label_brand" prop="brand_id">
          <a-select
            v-model="form.brand_id"
            :default-value="form.brand_id"
            :disabled="submitLoading"
            :placeholder="translations.quote_form_placeholder_brand"
          >
            <a-select-option v-for="(brand, i) in brands" :key="i" :value="brand.id">
              {{ brand.name }}
            </a-select-option>
          </a-select>
        </a-form-model-item>
        <a-form-model-item :label="translations.quote_form_label_solution" prop="solution">
          <a-radio-group v-model="form.solution" :disabled="submitLoading">
            <a-radio-button v-for="(solutionItem, i) in solutionsList" :key="i" :value="solutionItem.key">
              {{ solutionItem.value }}
            </a-radio-button>
          </a-radio-group>
        </a-form-model-item>
        <a-form-model-item 
          v-if="form.solution == 'cloud'" 
          :label="translations.quote_form_label_subscription" 
          prop="subscription_type"
        >
          <a-radio-group 
            v-model="form.subscription_type"
            :disabled="submitLoading"
            :placeholder="translations.quote_form_placeholder_subscription"
          >
            <a-radio-button v-for="(subscription, i) in subscriptions" :key="i" :value="subscription.key">
              {{ subscription.value }}
            </a-radio-button>
          </a-radio-group>
        </a-form-model-item>
      </a-col>
      <a-col :offset="2" :md="7">
        <a-form-model-item :label="translations.quote_form_label_months" prop="usermonths">
          <a-input-number 
            v-model="form.usermonths" 
            :disabled="submitLoading" 
            :min="1"
            @change="recountDate(form, 'due_date', 'start_date', true)"
          />
        </a-form-model-item>
        <a-form-model-item :label="translations.quote_form_label_users" prop="userlimit">
          <a-input-number v-model="form.userlimit" :disabled="submitLoading" :min="1" />
        </a-form-model-item>
        <a-form-model-item :label="translations.quote_form_label_start_date" prop="start_date">
          <a-date-picker
            v-model="form.start_date"
            :format="dateFormat"
            :show-time="false"
            :disabled="submitLoading"
            @change="recountDate(form, 'due_date', 'start_date', true)"
          />
        </a-form-model-item>
        <a-form-model-item :label="translations.quote_form_label_due_date" prop="due_date">
          <a-date-picker
            v-model="form.due_date"
            :format="dateFormat"
            :show-time="false"
            :disabled="submitLoading"
            @change="recountDate(form, 'start_date', 'due_date', false)"
          />
        </a-form-model-item>
      </a-col>
    </a-row>
  </a-form-model>
</template>

<script>

export default {
  name: "QuoteForm",
  props: {
    form: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    },
    submitLoading: {
      type: Boolean,
      default: false
    },
    availableVariables: {
      type: Object,
      default: () => {}
    }
  },
  computed: {
    solutionsList() {
      const vars = this.availableVariables;
      return vars?.availableSolutions || [];
    },
    subscriptions() {
      const vars = this.availableVariables;
      return vars.availableSubscriptionTypes.filter(item => item.key !== "none") || [];
    },
    brands() {
      return this.availableVariables?.availableBrands || [];
    },
    currencies() {
      return this.availableVariables?.availableCurrencies || [];
    },
    dateFormat() {
      const allSettings = this.$store.state.allSettings;
      if (!allSettings) return "DD.MM.YYYY";
      let rubyFormat = allSettings.date_format;
      rubyFormat = rubyFormat ? rubyFormat : "";
      return this.dateFormatter(rubyFormat);
    },
    rules() {
      const rules = {
        usermonths: [
          { 
            required: true, 
            message: this.translations.quote_form_validation_months_required, 
            trigger: 'blur' 
          }
        ],
        userlimit: [
          { 
            required: true, 
            message: this.translations.quote_form_validation_users_required, 
            trigger: 'blur' 
          }
        ],
        solution: [
          { 
            required: true, 
            message: this.translations.quote_form_validation_solution_required, 
            trigger: 'change' 
          }
        ],
        currency: [
          { 
            required: true, 
            message: this.translations.quote_form_validation_currency_required, 
            trigger: 'change' 
          }
        ],
        name: [
          { 
            required: true, 
            message: this.translations.quote_form_validation_name_required, 
            trigger: 'blur' 
          }
        ],
        brand_id: [
          { 
            required: true, 
            message: this.translations.quote_form_validation_brand_required, 
            trigger: 'blur' 
          }
        ],
        subscription_type: [
          { 
            required: true, 
            message: this.translations.quote_form_validation_subscription_required, 
            trigger: 'blur' 
          }
        ]
      };
      return rules;
    }
  },
  methods: {
    validate(callback) {
      this.$refs.quote.validate(valid => callback(valid));
    }
  }
};
</script>
