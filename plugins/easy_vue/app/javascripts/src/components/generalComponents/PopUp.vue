<template>
  <div :class="bem.ify(block, element + '-wrapper')">
    <div
      v-blur-closing="{
        handler: 'onBlur',
        exclude: excludedItems
      }"
      :class="`${bem.ify(block, element)} ${popUpSizeClass}`"
      :style="currentStyle"
    >
      <component
        :is="currentComponent"
        :bem="bem"
        :data="currentData"
        :task="task"
        :entity="entity"
        :options="currentOptions"
        :custom-values="customValues"
        :translations="translations"
        :in-pop-up="true"
        @confirmed="setConfirm($event)"
        @onBlur="onBlur"
        @data-change="$emit('data-change', $event)"
      />
    </div>
  </div>
</template>

<script>
import Coworkers from "./../issue/Coworkers";
import Tags from "./../issue/Tags";
import MergeRequestDetail from "./../issue/MergeRequestDetail";
import ShortUrl from "./../issue/ShortUrl";
import OnlineEdit from "./../issue/OnlineEdit";
import TaskList from "./../generalComponents/TaskList";
import TaskListPopUp from "./../issue/TaskListPopUp";
import AttendanceOverview from "./../attendance/AttendanceOverview";
import Repeating from "../meeting/Repeating";
import InvitationsPopup from "../meeting/InvitationsPopup";
import Duration from "./../issue/Duration";
import ReallocateSpentTime from "./../issue/ReallocateSpentTime";
import RequiredCustomFieldsPopup from "./customFields/RequiredCustomFieldsPopup";
// eslint-disable-next-line no-unused-vars
import blurClosing from "./../../directives/blurClosing.js";
import Confirm from "./../generalComponents/Confirm";

export default {
  name: "Popup",
  components: {
    Coworkers,
    Tags,
    Confirm,
    ShortUrl,
    OnlineEdit,
    TaskList,
    TaskListPopUp,
    AttendanceOverview,
    Repeating,
    InvitationsPopup,
    Duration,
    ReallocateSpentTime,
    RequiredCustomFieldsPopup,
    MergeRequestDetail
  },
  props: {
    bem: {
      type: Object,
      default: () => {}
    },
    component: {
      type: [String, Object],
      default: () => ""
    },
    customValues: {
      type: Array,
      default: () => []
    },
    top: {
      type: [String, Number],
      default: () => ""
    },
    align: {
      type: Object,
      default: () => {}
    },
    options: {
      type: [Array, Object],
      default: () => []
    },
    extraData: {
      type: Object,
      default: () => {}
    },
    customStyles: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    },
    task: {
      type: Object,
      default: () => {}
    },
    entity: {
      type: Object,
      default: () => {}
    }
  },
  data() {
    return {
      excludedItems: [],
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    currentComponent() {
      return this.$props.component;
    },
    currentOptions() {
      return this.$props.options;
    },
    currentData() {
      return this.$props.extraData;
    },
    currentStyle() {
      const alignment = this.$props.align;
      const customStyles = this.$props.customStyles;
      const style = { ...alignment, ...customStyles };
      return style;
    },
    popUpSizeClass() {
      let popUpClass = "popup-big";
      if (
        (this.currentData && this.currentData.inline) ||
        this.currentComponent === "Confirm"
      ) {
        popUpClass = "popup-inline";
      }
      return popUpClass;
    }
  },
  methods: {
    onBlur(e) {
      this.$emit("onBlur", e);
    },
    setConfirm(value) {
      this.$emit("confirmed", value);
    }
  }
};
</script>
