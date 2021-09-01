<template>
  <ul v-if="items.length" class="vue-modal__list" :class="listClass">
    <template v-if="items.length > 3">
      <span v-for="index in 3" :key="index">
        <li v-if="showListItems" :class="itemClass">
          <slot name="item" :index="index">
            {{ $props.items[index - 1].name }}
          </slot>
        </li>
      </span>
    </template>
    <template v-else>
      <span v-for="(item, index) in items" :key="index">
        <li :class="itemClass">
          <slot name="item" :index="index">
            {{ item.name }}
          </slot>
        </li>
      </span>
    </template>
    <span
      v-if="items.length > 3"
      ref="list-more-btn"
      class="list__show-more excluded"
      :title="$store.state.allLocales.label_note_show_more"
      @click="showMore($event)"
    >
      ...
    </span>
  </ul>
</template>

<script>
export default {
  name: "List",
  props: {
    items: Array,
    popupType: String,
    bem: Object,
    options: Object
  },
  data() {
    return {
      showListItems: true
    };
  },
  computed: {
    itemClass() {
      const options = this.$props.options;
      if (!options || !options.itemClass) return "";
      return options.itemClass;
    },
    listClass() {
      const options = this.$props.options;
      if (!options || !options.listClass) return "";
      return options.listClass;
    }
  },
  methods: {
    showMore(event) {
      const popupType = this.$props.popupType;
      const buttonElement = this.$refs["list-more-btn"];
      const payload = {
        event,
        popupType,
        buttonElement
      };
      this.$emit("list-more", payload);
    }
  }
};
</script>

<style lang="scss" scoped></style>
