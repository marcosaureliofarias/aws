<template>
  <div
    :class="bem.ify(bem.block, 'notification-wrapper') + ` ${backdropClass}`"
  >
    <div :class="bem.ify(bem.block, 'notification') + ` ${designType}`">
      <slot>
        <p
          :class="bem.ify(bem.block, 'notification-text')"
          v-html="notification.text"
        />
      </slot>
      <a
        href="#"
        :class="
          bem.ify(bem.block, 'notification-icon', 'close') + ` icon-cancel-alt`
        "
        @click.prevent="$store.state.notification = ''"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: "Notification",
  props: {
    bem: Object,
    type: String,
    backdrop: Boolean
  },
  data() {
    return {
      timer: null,
      icon: "",
      block: this.$props.bem.block,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase()
    };
  },
  computed: {
    notification() {
      return this.$store.state.notification;
    },
    designType() {
      if (this.$props.type) return this.$props.type;
      return this.$store.state.notification.type;
    },
    backdropClass() {
      return this.$props.backdrop
        ? bem.ify(bem.block, "notification-wrapper", "withBackdrop")
        : "";
    }
  },
  mounted() {
    this.notificationOpen();
  },
  methods: {
    notificationOpen() {
      const success = {
        delete: true
      };
      if (this.timer) clearTimeout(this.timer);
      if (this.$store.state.notification.type === "success") {
        this.timer = setTimeout(() => {
          this.$store.commit("setNotification", { success });
        }, 2000);
      }
    }
  }
};
</script>

<style scoped></style>
