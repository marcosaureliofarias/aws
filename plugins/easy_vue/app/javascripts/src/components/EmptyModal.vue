<template>
  <Wrapper
    v-if="$store.state.showModal"
    :block="'vue-modal'"
    :previous-path-name="previousPathName"
    :previous-search="previousSearch"
    :options="options"
    :class="wrapperClasses"
  >
    <template slot="headline">
      <h2 class="vue-modal__headline">
        {{ options.header }}
      </h2>
    </template>
    <template slot="body">
      <div ref="htmlBody" />
      <div v-if="!actionButtons.length && showButtonBar" class="vue-modal__button-panel">
        <template>
          <button class="button-positive" @click="defaultSave">
            {{ this.$store.state.allLocales.button_save }}
          </button>
          <button class="button" @click="defaultCancel">
            {{ this.$store.state.allLocales.button_cancel }}
          </button>
        </template>
      </div>
    </template>
    <Sidebar
      v-if="actionButtons.length"
      slot="sidebar"
      :actions="actionButtons"
      :bem="bem"
    />
  </Wrapper>
</template>

<script>
import Wrapper from "./generalComponents/Wrapper";
import Sidebar from "./generalComponents/Sidebar";
import locales from "../graphql/locales/empty";
import actionSubordinates from "../store/actionHelpers";

export default {
  name: "EmptyModal",
  components: { Wrapper, Sidebar },
  props: {
    options: Object,
    bemBlock: String,
    showButtonBar: Boolean,
    actionButtons: {
      type: Array,
      default() {
        return [];
      }
    }
  },
  data() {
    return {
      previousPathName: "",
      previousSearch: "",
      bem: {
        block: this.$props.bemBlock,
        ify: function(b, e, m) {
          let output = b;
          output += e ? "__" + e : "";
          output = m ? output + " " + output + "--" + m : output;
          return output.toLowerCase();
        }
      }
    };
  },
  computed: {
    wrapperClasses() {
      return {
        [`${this.bemBlock}--empty`]: true,
        [`${this.bemBlock}--no-sidebar`]: !this.actionButtons.length
      };
    }
  },
  mounted() {
    this.openModal();
  },
  methods: {
    async openModal() {
      await this.getLocales();
      const payloadShow = {
        name: "showModal",
        value: true,
        level: "state"
      };
      await this.$store.commit("setStoreValue", payloadShow);
      await this.$nextTick();
      //fu fu kod
      $(this.$refs.htmlBody).html(this.options.body);
      $(this.$refs.htmlBody)
        .find(".title,.form-actions")
        .remove();
      initEasyAutocomplete();
      EasyToggler.ensureToggle();
      displayTabsButtons();
    },
    async getLocales() {
      const payload = {
        name: "allLocales",
        apolloQuery: {
          query: locales
        },
        processFunc: (data) => actionSubordinates.getLocales(data)
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    defaultSave() {
      const form = this.$el.querySelector("form");
      if (!form) return;
      if (form.reportValidity()) form.submit();
    },
    defaultCancel() {
      const payload = {
        name: "showModal",
        value: false,
        level: "state"
      };
      this.$store.commit("setStoreValue", payload);
    }
  }
};
</script>

<style scoped></style>
