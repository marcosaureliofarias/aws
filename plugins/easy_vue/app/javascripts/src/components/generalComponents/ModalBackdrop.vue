<template>
  <div :class="`${block}__mask`">
    <div ref="wrapper" :class="`${block} ${block}__wrapper`">
      <div
        :class="`${block}__container ${block}__container--${modificator}`"
        :style="customStyles"
      >
        <div :class="`${block}__main`">
          <h2 :class="`${block}__headline ${block}__headline--faker`" />
          <div :class="`${block}__modal-content`">
            <section id="detail" :class="`${block}__section`">
              <ul :class="bem.ify(block, 'attributes')">
                <li
                  v-for="i in 10"
                  :key="i"
                  :class="`${block}__attribute--fake`"
                >
                  <div :class="`gradient label`" />
                  <div
                    :class="`gradient u-showing editable-input__wrapper--fake`"
                  />
                </li>
              </ul>
              <div :class="bem.ify(block) + '__fake-data'">
                <div :class="`${bem.ify(block)}__fake-data__header gradient`" />
                <div :class="`${bem.ify(block)}__fake-data__body gradient`" />
                <div :class="`${bem.ify(block)}__fake-data__buttons`" />
                <div
                  :class="
                    `${bem.ify(block)}__fake-data__header ${bem.ify(
                      block
                    )}__fake-data__header--journal gradient`
                  "
                />
                <div
                  :class="
                    `${bem.ify(block)}__fake-data__body ${bem.ify(
                      block
                    )}__fake-data__body--journal gradient`
                  "
                />
                <div
                  :class="
                    `${bem.ify(block)}__fake-data__header ${bem.ify(
                      block
                    )}__fake-data__header--journal gradient`
                  "
                />
                <div
                  :class="
                    `${bem.ify(block)}__fake-data__body ${bem.ify(
                      block
                    )}__fake-data__body--journal gradient`
                  "
                />
              </div>
            </section>
          </div>
        </div>
        <div :class="`${block}__sidebar-wrapper`" tabindex="0">
          <div :class="`${block}__sidebar`">
            <div :class="`${block}__legend reference`" />
            <ul :class="bem.ify(block, 'controls')">
              <li
                v-for="i in 6"
                :key="i"
                :class="
                  `${block}__sidebar-item ${block}__sidebar-item--fake gradient`
                "
              />
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "ModalBackdrop",
  props: {
    block: {
      type: String,
      default: "vue-modal",
    },
    modificator: {
      type: String,
      default: () => "",
    },
    options: {
      type: Object,
      default: () => {},
    },
    bem: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    customStyles() {
      const options = this.$props.options;
      return options && options.customStyles ? options.customStyles : "";
    },
  },
  mounted() {
    // disable page scrolling if modal is opened
    document.body.style.overflow = "hidden";
  },
};
</script>
<style lang="scss" scoped>
.vue-modal__sidebar {
  justify-content: flex-start;
}
</style>
