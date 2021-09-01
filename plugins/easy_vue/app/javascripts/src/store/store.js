import Vue from "vue";
import Vuex from "vuex";
import mutations from "./mutations";
import actions from "./actions";
import axios from "axios";

Vue.use(Vuex, axios);
Vue.config.productionTip = false;
export const getModalStore = () => {
  return new Vuex.Store({
    state: {
      showModal: false,
      defaultAvatarUrl:
        "//www.gravatar.com/avatar/c53a7bf228d947d721b44247d69e1cf4?rating=PG&size=50&default=identicon",
      activities: [],
      allAvailableEmojis: {},
      silentHours: 0,
      assignee: null,
      users: null,
      activityEvent: {},
      user: null,
      allLocales: {},
      assignableUsers: [],
      onlyModalContent: false,
      newAvailableWatchers: [],
      parentTasks: [],
      pluginsList: {
        checklists: false,
        easyGitIssue: false,
        easySprint: false,
        timeEntries: false,
        easyEmojis: false,
      },
      ryses: {
        duration: false
      },
      notification: "",
      tags: [],
      additionalDataFetched: false,
      fetchAllJournals: false,
      preventModalClose: false,
      initialState: {},
      attachmentsCustomValues: [],
      topMenuHeight: null,
      wip: false,
      shortcuts: [],
      backdrop: true
    },
    mutations: mutations,
    actions: actions
  });
};