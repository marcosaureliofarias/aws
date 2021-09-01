<template>
  <div class="modal-summary">
    <a-statistic :title="translations.acquisition_summary_name_title" :value="form.name" />
    <a-statistic :title="translations.acquisition_summary_price_title" :suffix="form.currency" :value="form.price" />
    <a-row type="flex">
      <a-col>
        <a-statistic :title="translations.acquisition_summary_months_title" :value="form.usermonths" />
        <a-statistic v-if="form.brand" :title="translations.acquisition_summary_brand_title" :value="form.brand.name" />
      </a-col>
      <a-col>
        <a-statistic :title="translations.acquisition_summary_users_title" :value="form.userlimit" />
        <a-statistic :title="translations.acquisition_summary_solution_title" :value="form.solution" />
      </a-col>
    </a-row>
  </div>
</template>
<script>
export default {
  name: "ModalSummary",
  props: {
    form: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    }
  }
};
</script>