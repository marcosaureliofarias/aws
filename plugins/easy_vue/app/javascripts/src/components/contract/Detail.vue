<template>
  <section id="detail" :class="bem.ify(bem.block, 'section')">
    <ul :class="bem.ify(bem.block, 'attributes')">
      <Attribute :id="id" :bem="bem" :data="startDate" />
      <Attribute :id="id" :bem="bem" :data="dueDate" />
      <Attribute :id="id" :bem="bem" :data="product" />
      <Attribute :id="id" :bem="bem" :data="solution" />
      <Attribute :id="id" :bem="bem" :data="licenseKey" />
      <Attribute :id="id" :bem="bem" :data="currency" />
      <Attribute :id="id" :bem="bem" :data="discount" />
      <Attribute :id="id" :bem="bem" :data="totalPrice" />
      <Attribute :id="id" :bem="bem" :data="userCount" />
      <Attribute :id="id" :bem="bem" :data="userLimit" />
      <Attribute :id="id" :bem="bem" :data="customRepository" />
      <Attribute :id="id" :bem="bem" :data="implementationHours" />
      <Attribute :id="id" :bem="bem" :data="easyApplication" />
      <Attribute :id="id" :bem="bem" :data="createdAt" />
      <Attribute :id="id" :bem="bem" :data="updatedAt" />
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
export default {
  name: "Detail",
  components: { Attribute },
  props: {
    id: [Number, String],
    easyContract: Object,
    bem: Object,
    translations: Object
  },
  data() {
    return {
      startDate: {
        labelName: this.translations.easy_contracts_field_start_date,
        value: this.dateFormat(this.easyContract.startDate) || "",
        inputType: "date",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      dueDate: {
        labelName: this.translations.easy_contracts_field_end_date,
        value: this.dateFormat(this.easyContract.dueDate) || "",
        inputType: "date",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      createdAt: {
        labelName: this.translations.easy_contracts_field_created_at,
        value: this.dateFormat(this.easyContract.createdAt) || "",
        inputType: "date",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      updatedAt: {
        labelName: this.translations.easy_contracts_field_updated_at,
        value: this.dateFormat(this.easyContract.updatedAt) || "",
        inputType: "date",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      currency: {
        labelName: this.translations.easy_contracts_field_currency,
        value: this.easyContract.currency || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      customRepository: {
        labelName: this.translations.easy_contracts_field_custom_repository,
        value: this.textilizeBool(this.easyContract.customRepository),
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      discount: {
        labelName: this.translations.easy_contracts_field_discount,
        value: this.easyContract.discount || "0",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      implementationHours: {
        labelName: this.translations.easy_contracts_field_implementation_hours,
        value: this.easyContract.implementationHours || "0",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      licenseKey: {
        labelName: this.translations.easy_contracts_field_license_key,
        value: this.easyContract.licenseKey || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      totalPrice: {
        labelName: this.translations.easy_contracts_field_total_price,
        value: this.parseText(this.easyContract.totalPrice),
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      product: {
        labelName: this.translations.easy_contracts_field_product,
        value: this.easyContract.product,
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      solution: {
        labelName: this.translations.easy_contracts_field_solution,
        value: this.easyContract.solution,
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      userCount: {
        labelName: this.translations.easy_contracts_field_user_count,
        value: this.easyContract.userCount || "0",
        inputType: "int",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      userLimit: {
        labelName: this.translations.easy_contracts_field_user_limit,
        value: this.easyContract.userLimit || "0",
        inputType: "int",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      easyApplication: {
        labelName: this.translations.easy_contracts_field_easy_application,
        value: this.easyContract.easyApplication ? this.easyContract.easyApplication.url : "",
        inputType: "int",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false,
        withLink: true,
        link: this.easyContract.easyApplication ? this.easyContract.easyApplication.easyWebApplicationPath : ""
      }
    };
  },
  methods: {
    parseText(html) {
      // parse text from given html
      const element = document.createElement("div");
      element.innerHTML = html;
      const text = element.querySelector("span").textContent;
      return text || "";
    }
  }
};
</script>

<style scoped></style>
