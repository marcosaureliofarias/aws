<template>
  <section id="invoices" :class="bem.ify(bem.block, 'section')">
    <h2 :class="bem.ify(bem.block, 'heading') + ' icon icon-invoice'">
      {{ `${translations.label_easy_invoice_plural} (${invoices.length}):` }}
    </h2>
    <Tags
      :tags="invoices"
      :block="block"
      :tags-path="'easyInvoicePath'"
      :label="'number'"
    />
  </section>
</template>

<script>
import Tags from "../generalComponents/Tags";
export default {
  name: "Invoices",
  components: { Tags },
  props: {
    bem: Object,
    invoices: Array,
    block: String,
    translations: Object
  }
};
</script>

<style scoped></style>
