import Vue from "vue";
let handleOutsideClick;

const blurClosing = {
  bind(el, binding, vnode) {
    handleOutsideClick = e => {
      e.stopPropagation();
      const { handler, exclude } = binding.value;
      // Add a excluded items because of external components that can be cliked
      // They dont have excluded class so should be added manually
      if (exclude && exclude.find(el => el === e.target.className)) return;
      if (!el.contains(e.target) && !e.target.classList.contains("excluded") && !e.target.closest(".excluded")) {
        vnode.context[handler]();
      }
    };
    document.addEventListener("click", handleOutsideClick);
    document.addEventListener("touchstart", handleOutsideClick);
  },
  unbind() {
    document.removeEventListener("click", handleOutsideClick);
    document.removeEventListener("touchstart", handleOutsideClick);
  }
};

export default Vue.directive("blur-closing", blurClosing);
