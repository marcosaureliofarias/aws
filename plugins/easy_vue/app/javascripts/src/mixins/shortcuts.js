/*
  USAGE:
    Register your shortcut to some element via ref
    Specify key you want to check (you can also specify CTRL+key)
    Use focus if you want also focus to element after scroll
    If focusable element is CKeditor, specify its id to ckeditor attribute
    this.registerShortcut({
        ref: this.$refs.comment,
        key: "c or CTRL+c",
        options: {
          focus: true,
          ckeditor: this.commentAddConfig.id
        }
    });

    TIP: You can specify one shortcut for "CTRL+a" and one different for "a"
*/

export default {
  methods: {
    registerShortcut(shortcut) {
      const { key, ref } = shortcut;
      if (!key || !ref) return;
      const payload = {
        name: "shortcuts",
        value: shortcut,
        level: "state",
        toPush: true
      };
      this.$store.commit("setStoreValue", payload);
    },
    allowShortcuts() {
      document.addEventListener("keyup", this.attachShortcutEvent);
    },
    attachShortcutEvent(e) {
      // if keypress was in input|textarea|select then dont trigger shortcut
      const test = /input|select|textarea/i.test(e.target.nodeName);
      if (!e.target || test || e.target.type === "text") return;
      // find first shortcut with pressed key
      const shortcut = this.$store.state.shortcuts.find(shortcut => {
        const regexp = /ctrl\+/gi;
        const ctrl = shortcut.key.match(regexp);
        if (!ctrl) {
          return shortcut.key === e.key && !e.ctrlKey && !e.metaKey;
        } else {
          const parsedKey = shortcut.key.replace(regexp, "");
          return parsedKey === e.key && (e.ctrlKey || e.metaKey);
        }
      });
      if (!shortcut) return;
      e.preventDefault();
      const { ref, options } = shortcut;
      this.moveAndFocus(ref, options);
    },
    moveAndFocus(ref, options) {
      if (!ref) return;
      const modalContent = document.querySelector(".vue-modal__modal-content");
      if (!modalContent) return;
      const overView = document.querySelector(".vue-modal__overview");
      if (ref.$el) {
        ref.$el.scrollIntoView();
      } else ref.scrollIntoView();
      // we need to focus in next browser rendering phase to not to focus to input with key that we pressed,
      // we are not able to use this.$nextTick() because its next rendering phase of Vue.js not browser
      const overViewHeight = overView ? overView.offsetHeight : 0;
      if (overViewHeight) {
        // because of sticky position of overView, we need to move top its calculated height
        modalContent.scrollTop -= overViewHeight;
      }

      if (
        options.click
      ) {
        ref.click();
      }

      if (!options.focus) return;
      setTimeout(() => {
        if (options.ckeditor && CKEDITOR) {
          CKEDITOR.instances[options.ckeditor].focus();
          return;
        }
        let selector;
        if (ref.$el){
          selector =
            ref.$el.querySelector("input") || ref.$el.querySelector("textarea");
        }
        if (!selector) return;
        selector.focus();
      }, 0);
    }
  }
};
