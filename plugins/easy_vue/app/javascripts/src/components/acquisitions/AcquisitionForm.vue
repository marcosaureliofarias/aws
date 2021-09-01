<template>
  <a-form-model 
    ref="acquisition" 
    :model="form"
    layout="horizontal" 
    :rules="rules" 
  >
    <a-form-model-item :label="translations.acquisition_label_start_date" prop="startDate">
      <a-date-picker
        v-model="form.startDate"
        :format="dateFormat"
        :show-time="false"
        :disabled="submitLoading"
        @change="recountDate(form, 'dueDate', 'startDate', true)"
      />
    </a-form-model-item>
    <a-form-model-item :label="translations.acquisition_label_due_date" prop="dueDate">
      <a-date-picker
        v-model="form.dueDate"
        :format="dateFormat"
        :show-time="false"
        :disabled="submitLoading"
        @change="recountDate(form, 'startDate', 'dueDate', false)"
      />
    </a-form-model-item>
    <a-form-model-item
      v-if="form.solution === 'cloud'" 
      :label="ewaSelectLabel"
      prop="easyWebApplication"
    >
      <a-select
        v-model="easyWebApplication"
        :placeholder="translations.acquisition_placeholder_select_ewa"
        :disabled="ewaSelectDisabled"
      >
        <a-select-option v-for="(instance, i) in ewaInstaces" :key="i" :value="instance.id">
          {{ instance.value }}
        </a-select-option>
      </a-select>
    </a-form-model-item>
    <div v-if="form.solution === 'cloud' && showEwaErrorMessage">
      <p>{{ translations.acquisition_no_ewa_instances_message }}</p>
    </div>
  </a-form-model>
</template>
<script>
export default {
  name: "AcquisitionForm",
  props: {
    id: {
      type: [String, Number],
      default: ""
    },
    value: {
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
    ewaInstaces: {
      type: Array,
      default: () => []
    }
  },
  data() {
    return {
      form: {}
    };
  },
  computed: {
    easyWebApplication: {
      get() { return this.value.easyWebApplication; },
      set(easyWebApplication) { this.$emit('input', {...this.value, easyWebApplication }); }
    },
    ewaSelectLabel() {
      return this.form.easyWebApplication 
        ? this.translations.acquisition_label_selected_ewa 
        : this.translations.acquisition_label_select_ewa;
    },
    dateFormat() {
      const allSettings = this.$store.state.allSettings;
      if (!allSettings) return "DD.MM.YYYY";
      let rubyFormat = allSettings.date_format;
      rubyFormat = rubyFormat ? rubyFormat : "";
      return this.dateFormatter(rubyFormat);
    },
    ewaSelectDisabled() {
      return this.submitLoading || !this.ewaInstaces || !this.ewaInstaces.length;
    },
    showEwaErrorMessage() {
      return (!this.ewaInstaces || !this.ewaInstaces.length);
    },
    rules() {
      const rules = {
        startDate: [
          { 
            required: true, 
            message: this.translations.acquisition_validation_start_date_required, 
            trigger: 'change' 
          }
        ],
        dueDate: [
          { 
            required: true, 
            message: this.translations.acquisition_validation_due_date_required, 
            trigger: 'change' 
          }
        ],
        solution: [
          { 
            required: true, 
            message: this.translations.acquisition_validation_solution_required, 
            trigger: 'change' 
          }
        ],
        easyWebApplication: [
          { 
            required: true, 
            message: this.translations.acquisition_validation_ewa_required, 
            trigger: 'change' 
          }
        ],
      };
      return rules;
    }
  },
  created() {
    this.form = this.value;
  },
  methods: {
    validate(callback) {
      this.$refs.acquisition.validate(valid => callback(valid));
    }
  }
};
</script>
