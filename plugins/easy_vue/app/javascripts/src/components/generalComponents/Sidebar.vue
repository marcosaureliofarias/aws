<template>
  <div
    :class="
      (sidebarOpen ? bem.ify(bem.block, 'sidebar', 'opened') : '') +
        ' ' +
        bem.ify(bem.block, 'sidebar')
    "
  >
    <div :class="bem.ify(bem.block, 'sidebar-button', 'control')">
      <a
        href="javascript:void(0)"
        class="icon"
        :class="sidebarOpen ? 'icon-arrow' : 'icon-back'"
        @click="showHideSidebar"
      />
    </div>
    <div>
      <h3 :class="bem.ify(bem.block, 'legend') + ' reference'">
        <a
          v-if="customUrl.length"
          class="vue-modal__pointer"
          :title="translations.button_show_details"
          :href="customUrl"
          target="_blank"
        >
          {{ reference }}
        </a>
      </h3>
      <ul :class="bem.ify(bem.block, 'controls')">
        <li
          v-for="(element, i) in activeItems"
          :key="i"
          :class="bem.ify(bem.block, 'sidebar-item') + ' excluded'"
        >
          <a
            :disabled="!element.active"
            :class="`button ${bem.ify(bem.block, 'sidebar-button')} excluded`"
            @click.prevent="buttonPressed($event, element)"
          >
            {{ element.name }}
          </a>
          <a
            v-if="element.showAddAction"
            :class="'button ' + bem.ify(bem.block, 'sidebar-button', 'add')"
            class="icon-add-action excluded"
            @click.prevent="element.onClick(element.ref, $event)"
          />
        </li>
      </ul>
      <h3 v-if="actions.length" :class="bem.ify(bem.block, 'legend')">
        {{ translations.button_actions }}
      </h3>
      <ul v-if="actions.length" :class="bem.ify(bem.block, 'controls')">
        <li
          v-for="(element, i) in actions"
          :key="i"
          :class="bem.ify(bem.block, 'sidebar-item')"
        >
          <a
            :class="getActionButtonClass(element)"
            data-remote="true"
            :href="element.href"
            @click="actionButtonFunc($event, element)"
          >
            {{ element.name }}
          </a>
        </li>
      </ul>
    </div>
    <transition>
      <Notification v-if="$store.state.notification" :bem="bem" />
    </transition>
    <slot name="popup" />
  </div>
</template>

<script>
import Notification from "./Notification";
export default {
  name: "Sidebar",
  components: { Notification },
  props: {
    active: {
      type: Array,
      default() {
        return [];
      }
    },
    reference: {
      type: String,
      default() {
        return "";
      }
    },
    bem: {
      type: Object,
      default() {
        return {};
      }
    },
    detailsPath: {
      type: String,
      default() {
        return "";
      }
    },
    actions: {
      type: Array,
      default() {
        return [];
      }
    },
    customUrl: {
      type: String,
      default() {
        return "";
      }
    }
  },
  data() {
    return {
      sidebarOpen: false,
      translations: this.$store.state.allLocales
    };
  },
  computed: {
    activeItems: {
      get() {
        const active = this.active.filter(item => item.isModuleActive);
        return active;
      },
      set(value) {
        this.active = value;
      }
    }
  },
  methods: {
    showHideSidebar() {
      this.sidebarOpen = !this.sidebarOpen;
    },
    actionButtonFunc(e, element) {
      if (element.href) return;
      if (element.disabled) return;
      e.stopPropagation();
      const eventData = e;
      if (element.needConfirm) {
        const action = () => element.func(element.params, this, eventData);
        this.$emit("confirm", {
          eventData,
          action,
          close: element.closeAfterEvent
        });
        return;
      }
      element.func(element.params, this, eventData);
      if (!element.closeAfterEvent) return;
      this.$emit("close");
    },
    buttonPressed(event, element) {
      this.scrollTo(element.anchor);
      if (!element.showAddAction) {
        element.onClick(event);
      }
    },
    getActionButtonClass(action) {
      const button = `button ${this.bem.ify(this.bem.block, "sidebar-button")}`;
      const disabled = action.disabled ? "disabled" : "";
      return `${button} ${disabled}`;
    }
  }
};
</script>

<style scoped></style>
