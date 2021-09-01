<template>
  <section id="crmCases" :class="bem.ify(bem.block, 'section')">
    <h2 :class="bem.ify(bem.block, 'heading') + ' icon icon-crm-1'">
      {{ `${translations.label_easy_contact_easy_crm_cases} (${crmCases.length}):` }}
    </h2>
    <Tags :tags="crmCases" :block="block" :tags-path="'easyCrmCasePath'" />
  </section>
</template>

<script>
import Tags from "../generalComponents/Tags";
export default {
  name: "CrmCases",
  components: { Tags },
  props: {
    bem: Object,
    crmCases: Array,
    block: String,
    translations: Object
  }
};
</script>

<style scoped></style>
