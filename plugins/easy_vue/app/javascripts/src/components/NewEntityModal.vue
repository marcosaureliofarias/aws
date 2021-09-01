<template>
  <div>
    <NewAttendanceModal
      v-if="entity === 'new_attendance'"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
      :options="options"
      :entity="newEntity"
      :translations="translations"
      :current-user="currentUser"
      @entity:changed="changeModalType"
    />
    <NewSalesActivityModal
      v-if="entity === 'new_entity_activity'"
      :is-mobile="isMobile"
      :bem-block="bemBlock"
      :options="options"
      :entity="newEntity"
      :translations="translations"
      :current-user="currentUser"
      @entity:changed="changeModalType"
    />
    <NewMeetingModal
      v-if="entity === 'new_meeting'"
      :bem-block="bemBlock"
      :entity="newEntity"
      :options="options"
      @entity:changed="changeModalType"
    />
    <NewIssueModal
      v-if="entity === 'new_issue'"
      :bem-block="bemBlock"
      :entity="newEntity"
      :translations="translations"
      :options="options"
      @entity:changed="changeModalType"
    />
    <NewQuoteModal
      v-if="entity === 'new_quote'"
      :id="id"
    />
  </div>
</template>

<script>
import NewAttendanceModal from "./NewAttendanceModal";
import NewSalesActivityModal from "./NewSalesActivityModal";
import NewMeetingModal from "./NewMeetingModal";
import NewIssueModal from "./NewIssueModal";
import NewQuoteModal from "./NewQuoteModal";
export default {
  name: "NewEntityModal",
  components: {
    NewAttendanceModal,
    NewSalesActivityModal,
    NewMeetingModal,
    NewIssueModal,
    NewQuoteModal
  },
  props: {
    id: {
      type: [String, Number],
      default: () => ""
    },
    entityType: {
      type: String,
      default: () => ""
    },
    bemBlock: {
      type: String,
      default: () => ""
    },
    options: {
      type: Object,
      default: () => {}
    },
    isMobile: {
      type: Boolean,
      default: () => false
    }
  },
  data() {
    return {
      newEntity: { type: this.$props.entityType },
      entity: this.$props.entityType
    };
  },
  computed: {
    currentUser() {
      return this.$store.state.user;
    },
    translations() {
      return this.$store.state.allLocales;
    }
  },
  async created() {
    if (!this.currentUser) {
      await this.getCurrentUser();
    }
  },
  methods: {
    // Open new modal when changing modal type
    async changeModalType(event) {
      const { inputValue } = event;
      if (this.timerInput) {
        clearTimeout(this.timerInput);
        this.timerInput = null;
      }
      this.timerInput = setTimeout(async () => {
        this.$store.state.showModal = false;
        this.changeEntity(inputValue);
      }, 100);
    },
    changeEntity(entity) {
      this.entity = entity.type;
      this.newEntity = entity;
      localStorage.setItem("easy_scheduler_modal", this.entity);
    }
  }
};
</script>

<style lang="scss" scoped></style>
