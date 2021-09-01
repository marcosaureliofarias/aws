<template>
  <a-modal
    class="form-modal"
    :title="title"
    :visible="$store.state.showModal"
    :width="width"
    @cancel="closeModal"
  >
    <a-skeleton :loading="loading" active :paragraph="{ rows: skeletonRows }">
      <slot />
    </a-skeleton>
    <template slot="footer">
      <div class="footer-buttons">
        <a-skeleton :loading="loading" active :paragraph="{ rows: 0 }">
          <slot name="footer" />
        </a-skeleton>
      </div>
    </template>
  </a-modal>
</template>

<script>
export default {
  name: "FormModalWrapper",
  props: {
    title: {
      type: String,
      default: ""
    },
    width: {
      type: String,
      default: "950px"
    },
    skeletonRows: {
      type: Number,
      default: 5
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  created() {
    this.init();
  },
  methods: {
    async init() {
      // open modal
      this.openModal();
      // wait to fetch data
      this.$emit("onModalOpen");
    },
    modalStateChange (value) {
      const payloadShow = {
        name: "showModal",
        value: value,
        level: "state"
      };
      this.$store.commit("setStoreValue", payloadShow);
    },
    openModal() {
      this.modalStateChange(true);
      const evt = new CustomEvent("vueModalFormOpened", {
        cancelable: false
      });
      document.dispatchEvent(evt);
    },
    closeModal() {
      this.modalStateChange(false);
      const evt = new CustomEvent("vueModalFormChanged", {
        cancelable: false
      });
      document.dispatchEvent(evt);
      EasyVue.modalInstance.$destroy();
      EasyVue.modalInstance = null;
    }
  }
};
</script>