<template>
  <div :class="bem.ify(block, element)">
    <h2 :class="bem.ify(block, `${element}-heading`) + ' popup-heading'">
      Online editing
    </h2>
    <div :class="bem.ify(block, `${element}-input-wrapper`)">
      <label :class="bem.ify(block, `${element}-item-label`)">
        Editing link: 
      </label>
      <input
        v-model="options.webdavUrl"
        type="text"
        :class="bem.ify(block, `${element}-input`)"
      />
      <p :class="bem.ify(block, `${element}-info-text`)">
        For online editing, copy this link and past it to your editor. Make sure that editor supports webdav protocol.
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: "OnlineEdit",
  props: {
    bem: Object,
    options: Object
  },
  data() {
    return {
      block: this.$props.bem.block,
      element: this.$options.name.toLowerCase()
    };
  }
};
</script>
