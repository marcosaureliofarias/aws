<template>
  <Attribute
    :bem="bem"
    :data="newEntitySelect"
    @child-value-change="$emit('entity:changed', $event)"
  />
</template>
<script>
import Attribute from "./generalComponents/Attribute";
export default {
  name: "NewEntitySelect",
  components: {
    Attribute
  },
  props: {
    bem: {
      type: Object,
      default: () => {}
    },
    entity: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      optionsArray: [
        {
          name: this.translations.easy_scheduler_label_new_attendance,
          type: "new_attendance",
        },
        { name: this.translations.easy_scheduler_label_meeting, type: "new_meeting" },
        { name: this.translations.field_issue, type: "new_issue" },
        {
          name: this.translations.easy_scheduler_label_new_sales_activity,
          type: "new_entity_activity",
        }
      ],
    };
  },
  computed: {
    newEntity() {
      const entity = this.$props.entity;
      const newEntity = entity.name ? entity : this.optionsArray.find(({ type }) => type === entity.type);
      return newEntity;
    },
    newEntitySelect() {
      const i18n = this.translations;
      return {
        labelName: i18n.label_new,
        value: this.newEntity,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "autocomplete",
        optionsArray: this.optionsArray,
        filterable: false,
        withSpan: false,
        editable: true,
        withLoading: false
      };
    }
  }
};
</script>

<style lang="scss" scoped></style>
