<template>
  <div id="notification" />
</template>

<script>
export default {
  name: "NotificationCenter",
  props: {
    config: {
      type: Object,
      default: () => {}
    }
  },
  created() {
    window.addEventListener("notify", ({ detail }) => {
      this.openNotification(detail);
    });
  },
  methods: {
    openNotification(config) {
      const type = config.type;
      const defaultDuration = 3;
      this.$notification[type]({
        bottom: config.bottom,
        message: config.message || "Simple message",
        description: config.description,
        btn: config.closeBtn,
        class: config.class,
        duration: config.duration || defaultDuration,
        icon: config.icon,
        style: config.style,
        closeIcon: config.closeIcon,
        onClick: async () => {
          config.onClick && await config.onClick();
        },
        onClose: async () => {
          config.onClose && await config.onClose();
        }
      });
    }
  }
};
</script>