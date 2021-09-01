import Vue from "vue";
import NotificationCenter from "./NotificationCenter";
import App from "./App";
import { getModalStore } from "./store/store";
import utils from "./mixins/utils";
import vSelect from "@easy/vue-select";
import Datetime from "vue2-datepicker";
import "vue2-datepicker/index.css";
import Attachments from "../src/components/issue/Attachments";
import shortcuts from "./mixins/shortcuts";
import "../src/plugins/adapters.js";
import {
  Table,
  Input,
  Button,
  Row,
  Select,
  Col,
  DatePicker,
  Radio,
  Modal,
  FormModel,
  Skeleton,
  InputNumber,
  Statistic,
  notification
} from "ant-design-vue";
import "../src/stylesheets/ant/index.less";

const plugins = [
  Table,
  Input,
  Button,
  Row,
  Select,
  Col,
  DatePicker,
  Radio,
  Modal,
  FormModel,
  Skeleton,
  InputNumber,
  Statistic
];

plugins.forEach(plugin => {
  Vue.use(plugin);
});

window.EasyVue = {};
window.EasyVue.modalData = window.EasyVue.modalData || {};
window.EasyVue.showModal = (entityType, ID, options) => {
  if (
    !window.hasOwnProperty("CKEDITOR") &&
    window.hasOwnProperty("ckSettings")
  ) {
    EasyVue.loadCkeditor();
  }
  // show loading indicator

  const indicator = document.getElementById("ajax-indicator");
  if (indicator) indicator.style.display = "block";

  Vue.mixin(utils);
  Vue.mixin(shortcuts);
  Vue.component("v-select", vSelect);
  Vue.component("datetime", Datetime);
  // Need to register component globaly bc of recursive calling in showing attachment versions
  Vue.component("Attachments", Attachments);
  const entityID = ID;
  options = options || {};
  if (entityType === "scroll") {
    entityType = "issue";
  }
  window.EasyVue.modalInstance = new Vue({
    store: getModalStore(),
    render: h =>
      h(App, {
        props: {
          entityType,
          entityID,
          options
        }
      })
  }).$mount("#app");
};

window.EasyVue.notify = () => {
  Vue.use(notification);
  Vue.prototype.$notification = notification;
  new Vue({
    render: h => h(NotificationCenter)
  }).$mount("#notification");
};

window.EasyVue.notify();

// easy schedule late because of CKeditor initialization
EASY.schedule.late(() => {
  window.addEventListener("hashchange", openModalFromUrlHash);
  openModalFromUrlHash();
});

// Namespace for better empty modal function calling
window.EasyVue.showGenericModal = options => {
  window.EasyVue.showModal("empty", null, options);
};

EasyVue.loadCkeditor = () => {
  window.EasyGem.loadModules(["easy_ckeditor"], () => {
    CKEDITOR.config.mentions = window.ckSettings.hasOwnProperty("mentions")
      ? window.ckSettings.mentions
      : [];
  });
};

EasyVue.handleActivityFeedChanges = issueID => {
  // decrease number of shown activities
  const feedCount = document.querySelector(
    "#easy_activity_feed_trigger .sign.count"
  );
  if (feedCount) {
    const actualValue = parseInt(feedCount.textContent);
    if (actualValue === 1) feedCount.remove();
    feedCount.textContent = (actualValue - 1).toString();
  }
  // remove issue box from activity feed
  const activitiesBody = document.querySelector(
    "#easy_servicebar_component_body > .activity-feed"
  );
  if (!activitiesBody) return;
  const issue = activitiesBody.querySelector(`a[data-issue-id="${issueID}"]`);
  if (!issue) return;
  const descriptionTerm = issue.closest("dt");
  descriptionTerm.nextElementSibling.remove();
  descriptionTerm.remove();
  const activitiesWrapper = document.querySelector(
    "dl.easy-activity-feed-activity-event"
  );
  // if last issue from activity feed was removed then remove whole box of activities
  if (!activitiesWrapper.childElementCount) activitiesWrapper.remove();
};
window.EasyVue.holdTargetWrapperHeight = function() {
  if (
    !EasyVue.modalData ||
    !EasyVue.modalData.openedFromElement ||
    !EasyVue.modalData.pageOffsetY
  )
    return;
  const el = EasyVue.modalData.openedFromElement;
  if (!el) return;
  el.style.height = "auto";
  window.screenY = window.scroll(0, EasyVue.modalData.pageOffsetY);
  EasyVue.modalData.pageOffsetY = null;
};

function openModalFromUrlHash() {
  // test if in url hash is modal string and if so, open modal with extracted type and id
  if (!EASY.currentUser || !EASY.currentUser.logged) return;
  const urlHash = window.location.hash;
  if (!urlHash) return;
  const regex = /modal-([a-zA-Z]+)-(\d+)/gi;
  const match = regex.exec(urlHash);
  if (!match || !match.length) return;
  const [matchString, modalType, id] = match;
  if (!matchString || !modalType || !id) return;
  if (window.EasyVue.modalInstance) return;
  EasyVue.showModal(modalType, id);
}
