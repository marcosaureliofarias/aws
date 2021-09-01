<template>
  <div class="ckeditor">
    <textarea :id="id" :value="value" />
  </div>
</template>

<script>
export default {
  name: "Ckeditor",
  props: {
    value: {
      type: String
    },
    id: {
      type: String,
      default: "editor"
    },
    height: {
      type: String,
      default: "90px"
    },
    toolbar: {
      type: String,
      default: () => "Extended"
    },
    language: {
      type: String,
      default: "en"
    },
    extraplugins: {
      type: String,
      default: ""
    },
    startupFocus: {
      type: Boolean,
      default: false
    },
    removePlugins: {
      type: String,
      default: "codesnippet"
    }
  },
  mounted() {
    const ckeditorId = this.id;
    const ckeditorConfig = {
      toolbar: this.toolbar,
      language: this.language,
      height: this.height,
      extraPlugins: this.extraplugins,
      startupFocus: this.startupFocus,
      removePlugins: this.removePlugins
    };
    CKEDITOR.replace(ckeditorId, ckeditorConfig);

    CKEDITOR.on("instanceReady", event => {
      this.afterCkeditorinited(event);
      event.removeListener();
    });
    this.afterCkeditorinited(false);
  },
  destroyed() {
    const ckeditorId = this.id;
    if (CKEDITOR.instances[ckeditorId]) {
      CKEDITOR.instances[ckeditorId].destroy();
    }
  },
  methods: {
    afterCkeditorinited(event) {
      if (!event) return;
      if (event.editor.name !== this.id) return;
      // if (!this.startupFocus) {
      //   const top = document.getElementById(event.editor.id + "_top");
      //   if (top) {
      //     top.style.display = "none";
      //   }
      // }
      CKEDITOR.instances[this.id].setData(this.value);
      CKEDITOR.instances[this.id].on("change", () => {
        let ckeditorData = CKEDITOR.instances[this.id].getData();
        if (ckeditorData !== this.value) {
          this.$emit("input", ckeditorData);
        }
      });
      // CKEDITOR.instances[this.id].on("focus", event => {
      //   const top = document.getElementById(event.editor.id + "_top");
      //   if (top) {
      //     top.style.display = "";
      //   }
      // });
      // CKEDITOR.instances[this.id].on("blur", event => {
      //   const top = document.getElementById(event.editor.id + "_top");
      //   if (top) {
      //     top.style.display = "none";
      //   }
      // });
    }
  }
};
</script>
