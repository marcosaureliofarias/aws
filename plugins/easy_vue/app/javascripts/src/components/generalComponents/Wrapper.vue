<template>
  <div :class="`${block}__mask`" @mousedown="checkModalClick">
    <div
      ref="wrapper"
      :class="`${block} ${block}__wrapper`"
      @keydown="closeOnEscape"
    >
      <div
        :class="`${block}__container ${block}__container--${modificator}`"
        :style="customStyles"
        @dragover.prevent="showDragAndDropPlaceholder = true"
      >
        <div
          v-if="showDragAndDropPlaceholder && enableFileDragAndDrop"
          :class="`${block}__drag-and-drop-wrapper`"
          @dragover.prevent="showDragAndDropPlaceholder = true"
          @dragleave.prevent="showDragAndDropPlaceholder = false"
          @drop.prevent="handleDrop"
        >
          <span class="icon-dropbox">
            <p>{{ translations.label_drop_anywhere_upload || "" }}</p>
          </span>
        </div>
        <div :class="`${block}__main`">
          <slot name="headline" />
          <slot name="button-panel" />
          <div
            ref="vue-modal__content"
            tabindex="0"
            :class="`${block}__modal-content`"
          >
            <slot name="body" />
          </div>
        </div>
        <div :class="`${block}__button--close-wrapper`">
          <button
            v-show="!this.$store.state.onlyModalContent"
            :class="`${block}__button--close button`"
            @click="closeModal"
          />
        </div>
        <div :class="`${block}__sidebar-wrapper`" tabindex="0">
          <slot name="sidebar" />
        </div>
        <slot name="button-panel" />
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: "Wrapper",
  props: {
    block: String,
    modificator: {
      type: String,
      default: () => ""
    },
    onCloseFnc: {
      type: Function,
      default() {
        return () => false;
      }
    },
    enableFileDragAndDrop: {
      type: Boolean,
      default: false
    },
    entityType: {
      type: String,
      default: () => ""
    },
    id: {
      type: [String, Number]
    },
    options: Object,
    translations: {
      type: Object,
      default: () => ({})
    }
  },
  data: () => ({
    showDragAndDropPlaceholder: false
  }),
  computed: {
    customStyles() {
      const options = this.$props.options;
      return options && options.customStyles ? options.customStyles : "";
    }
  },
  mounted() {
    // disable page scrolling if modal is opened
    document.body.style.overflow = "hidden";
    this.setUrlHash();
    this.removeIndicator();
    // focus to modal, to let users to be able scroll with keyboard arrows right after modal opens
    this.$refs["vue-modal__content"].focus();
  },
  methods: {
    setUrlHash() {
      if (!this.entityType || !this.id) return;
      window.location.hash = `modal-${this.entityType}-${this.id}`;
    },
    checkModalClick(e) {
      const excludedClasses = ["vue-modal__wrapper", "vue-modal__mask"];
      const clickOutside = excludedClasses.some(excludedClass => {
        return e.target.classList.value.includes(excludedClass);
      });
      if (!clickOutside) return;
      setTimeout(this.closeModal, 0);
    },
    removeIndicator() {
      const indicator = document.getElementById("ajax-indicator");
      if (indicator) indicator.style.display = "none";
    },
    async closeModal(fireEvent = true) {
      if (this.$store.state.wip) {
        const leave = confirm(
          this.$store.state.allLocales.text_warn_on_leaving_unsaved
        );
        if (!leave) {
          return;
        }
      }
      if (this.$store.state.preventModalClose) return;
      // we need to change url this way, because if we change only "window.location.hash", page jumps to the top
      window.history.pushState(
        "",
        "/",
        window.location.pathname + window.location.search
      );
      this.$props.onCloseFnc(fireEvent);
      // give overflow to body
      document.body.style.overflow = "auto";
      document.body.classList.remove("vueModalOpened");
      this.$store.state.showModal = false;
      this.setOldModalsStyle("block");
      this.showBackdrop(false);
      this.$refs.wrapper.removeEventListener("keydown", this.closeOnEscape);
      await this.$nextTick();
      EasyVue.modalInstance.$destroy();
      EasyVue.modalInstance = null;
    },
    closeOnEscape(e) {
      if (e.key === "Escape") {
        e.stopPropagation();
        this.closeModal();
      }
    },
    handleDrop(e) {
      this.showDragAndDropPlaceholder = false;
      this.$emit("wrapper:file-drop", e);
    }
  }
};
</script>

<style scoped></style>
