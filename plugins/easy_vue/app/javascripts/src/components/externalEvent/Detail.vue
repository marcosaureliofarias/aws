<template>
  <section id="detail" :class="bem.ify(bem.block, 'section')">
    <ul :class="bem.ify(bem.block, 'attributes')">
      <Attribute
        :id="id"
        :bem="bem"
        :data="range"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="calendarName"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="externalEventName"
      />
      <Attribute :id="id" :bem="bem" :data="synchronizedAt" />
      <Attribute :id="id" :bem="bem" :data="user" />
      <Attribute :id="id" :bem="bem" :data="place" />
      <Attribute :id="id" :bem="bem" :data="allDay" />
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";

export default {
  name: "Detail",
  components: { Attribute },
  props: {
    id: {
      type: [Number, String],
      default: () => 1
    },
    data: {
      type: Object,
      default: () => {}
    },
    bem: {
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
      showPopup: false,
      customPopupStyles: {
        position: "fixed !important",
        height: "300px",
        "max-width": "600px"
      },
      popUpOptions: "",
      alignment: null
    };
  },
  computed: {
    externalEvent() {
      return this.$props.data;
    },
    calendarName() {
      return {
        labelName: this.translations.easy_scheduler_label_calendar_url_name,
        value: this.externalEvent.easyIcalendar.name,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "text",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: false
      };
    },
    externalEventName() {
      return {
        labelName: this.translations.easy_scheduler_label_ical_event,
        value: this.externalEvent.summary,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "text",
        optionsArray: false,
        filterable: true,
        withSpan: false,
        editable: false
      };
    },
    user() {
      return {
        labelName: this.translations.field_user,
        value: this.externalEvent.easyIcalendar.user,
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "text",
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: false
      };
    },
    place() {
      return {
        labelName: this.translations.field_place_name,
        value: this.externalEvent.place,
        inputType: "text",
        optionsArray: false,
        filterable: false,
        withSpan: false,
        editable: false
      };
    },
    synchronizedAt() {
      return {
        labelName: this.translations.field_synchronized_at,
        value: this.dateFormat(this.externalEvent.easyIcalendar.synchronizedAt || ""),
        placeholder: "---",
        inputType: "text",
        optionsArray: false,
        attribute: "approved_at",
        withSpan: false,
        editable: false
      };
    },
    range() {
      return {
        labelName:`${this.translations.label_date_from}~${this.translations.label_date_to}`,
        placeholder: "---",
        date: [this.externalEvent.dtstart, this.externalEvent.dtend],
        inputType: "datetime",
        optionsArray: false,
        withSpan: false,
        editable: false,
        range: true
      };
    },
    allDay() {
      return {
        labelName: this.translations.field_all_day,
        placeholder: "---",
        value: this.textilizeBool(this.externalEvent.allDay),
        inputType: "text",
        optionsArray: false,
        withSpan: false,
        editable: false
      };
    },
  }
};
</script>

<style scoped></style>
