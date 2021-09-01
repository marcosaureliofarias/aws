<template>
  <transition name="modal">
    <div :class="bem.ify(bem.block, 'mask')" @mousedown="closeModal">
      <div :class="bem.ify(bem.block) + ' ' + bem.ify(bem.block, 'wrapper')">
        <div :class="bem.ify(bem.block, 'container')">
          <div :class="bem.ify(bem.block, 'main')">
            <h2
              :class="bem.ify(bem.block, 'headline') + ' color-scheme-modal '"
            >
              <InlineInput
                :id="project.id"
                :data="subjectInput"
                :value="subject"
                @child-value-change="saveSubject($event)"
              />
            </h2>
            <ProjectContent :bem="bem" :project="project" :translations="translations" />
          </div>
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
              <h3 :class="bem.ify(bem.block, 'legend')">
                {{ $store.state.allLocales.field_content }}
              </h3>
              <ul :class="bem.ify(bem.block, 'controls')">
                <li
                  v-for="(element, i) in activeItems"
                  :key="i"
                  :class="bem.ify(bem.block, 'sidebar-item') + ' excluded'"
                >
                  <a
                    :disabled="!element.active"
                    :class="'button ' + bem.ify(bem.block, 'sidebar-button') + ' excluded'"
                    @click.prevent="scrollTo(element.anchor)"
                  >
                    {{ element.name }}
                  </a>
                  <a
                    v-if="element.showAddAction"
                    :class="
                      'button ' + bem.ify(bem.block, 'sidebar-button', 'add')
                    "
                    class="icon-add-action"
                    :disabled="!element.active"
                    @click.prevent="element.onClick(element.ref, $event)"
                  />
                </li>
              </ul>
              <h3 v-if="actions.length" :class="bem.ify(bem.block, 'legend')">
                {{ $store.state.allLocales.button_actions }}
              </h3>
              <ul v-if="actions.length" :class="bem.ify(bem.block, 'controls')">
                <li
                  v-for="(element, i) in actions"
                  :key="i"
                  :class="bem.ify(bem.block, 'sidebar-item')"
                >
                  <a
                    :class="'button ' + bem.ify(bem.block, 'sidebar-button')"
                    @click="actionButtonFunc(element)"
                  >
                    {{ element.name }}
                  </a>
                </li>
              </ul>
            </div>
            <transition>
              <Notification v-if="$store.state.notification" :bem="bem" />
            </transition>
            <PopUp
              v-if="currentComponent && popUpOptions.length"
              :bem="bem"
              :align="alignment"
              :component="currentComponent"
              :options="popUpOptions"
              :excluded-items="excludedItems"
              @onBlur="currentComponent = null"
            />
          </div>
          <button
            v-show="!this.$store.state.onlyModalContent"
            :class="bem.ify(bem.block, 'button', 'close') + ' button'"
            @click="$emit('close')"
          />
        </div>
        <div :class="bem.ify(bem.block, 'actions')" />
      </div>
    </div>
  </transition>
</template>
<script>
import InlineInput from "../generalComponents/InlineInput";
import PopUp from "../generalComponents/PopUp";
import Notification from "../generalComponents/Notification";
import userQuery from "../../graphql/user";
import ProjectContent from "./ProjectContent";

export default {
  name: "ProjectContainer",
  components: {
    ProjectContent,
    InlineInput,
    PopUp,
    Notification
  },
  props: { project: Object, actionButtons: Array },
  data() {
    return {
      buttonsTitle: ["Close"],
      currentComponent: null,
      top: 0,
      popUpOptions: [],
      excludedItems: [],
      sidebarOpen: false,
      animated: false,
      allignement: {},
      translations: this.$store.state.allLocales,
      active: [
        {
          name: this.$store.state.allLocales.label_details,
          anchor: "#detail",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.field_description,
          anchor: "#description_anchor",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: "Member",
          anchor: "#member_list",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
        {
          name: this.$store.state.allLocales.label_history,
          anchor: "#history",
          active: true,
          isModuleActive: true,
          showAddAction: false,
          onClick() {
            return false;
          }
        },
      ],
      actions: this.$props.actionButtons,
      bem: {
        block: "vue-modal",
        ify: function(b, e, m) {
          var output = b;
          output += e ? "__" + e : "";
          output = m ? output + " " + output + "--" + m : output;
          return output.toLowerCase();
        }
      },
      subjectInput: {
        labelName: "subject",
        classes: { edit: ["u-editing"], show: ["u-showing"] },
        inputType: "text",
        withSpan: true
      },
      subject: this.$props.project.name
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
    },
    actionItems: {
      get() {
        return this.actions;
      },
      set(value) {
        this.actions = value;
      }
    }
  },
  mounted() {
    this.getCurrentUser();
    //hide loading indicator
    document.getElementById("ajax-indicator").style.display = "none";
  },
  methods: {
    closeModal(e) {
      const excludedClasses = ["vue-modal__wrapper", "vue-modal__mask"];
      const clickOutside = excludedClasses.some(excludedClass => {
        return e.target.classList.value.includes(excludedClass);
      });
      if (!clickOutside) return;
      this.$emit("close");
    },
    actionButtonFunc(element) {
      this.$emit("close");
      element.func(element.params);
    },
    saveSubject(newSubject) {
      if (newSubject.inputValue === this.subject) return;
      this.subject = newSubject.inputValue;
      const payload = {
        name: "name",
        reqBody: {
          project: {
            name: this.subject
          }
        },
        value: {
          name: this.subject
        },
        reqType: "patch",
        processFunc(type, message) {
          newSubject.showFlashMessage(type, message);
          if (newSubject.changeSelectedValue) {
            newSubject.changeSelectedValue();
          }
        }
      };
      this.$store.dispatch("saveProjectStateValue", payload);
    },
    getTop(e) {
      this.top = e.target.offsetTop + 30;
    },
    showHideSidebar() {
      this.sidebarOpen = !this.sidebarOpen;
    },
    getCurrentUser() {
      const payload = {
        name: "user",
        apolloQuery: {
          query: userQuery,
          variables: { id: EASY.currentUser.id }
        }
      };
      this.$store.dispatch("fetchStateValue", payload);
    }
  }
};
</script>
<style lang="scss">
.modal-feedback-link {
  color: #ffffff;
  font-size: 12px;
  margin-left: 10px;
  text-transform: capitalize;
}
.modal-icon-vue-link {
  margin-left: 10px;
}
</style>
