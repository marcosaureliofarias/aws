import apollo from "../apolloClient";
import journalsQuery from "../graphql/journals";
import issueValidate from "../graphql/mutations/issueValidate";
import timeEntriesQuery from "../graphql/timeEntries";
import axios from "axios";
import utils from "../mixins/utils";

const issueQuery = window.urlPrefix + "/issues/";
const projectQuery = window.urlPrefix + "/projects/";

const actions = {
  async actionsJudge({ state, dispatch }, payload) {
    if (state.localSave) {
      const valid = !!(await dispatch("validate", payload));
      return valid;
    } else {
      return await dispatch("saveIssueStateValue", payload);
    }
  },
  async saveIssueStateValue({ state, commit, dispatch }, payload) {
    const {
      name,
      url,
      reqBody,
      reqType,
      processFunc,
      localId,
      level = "issue"
    } = payload;
    const defaultIssueId = state.issue.id;
    const issueId = localId || defaultIssueId;
    const defaultUrl = issueQuery + issueId + ".json";
    const defaultReqType = "put";
    const success = state.allLocales.notice_successful_update;
    const setUrl = url || defaultUrl;
    const requestType = reqType || defaultReqType;
    const value =
      typeof payload.value === "object" ? payload.value[name] : payload.value;
    const options = {
      value,
      name,
      toPush: payload.toPush,
      level
    };
    const journalsPayload = {
      type: "issue",
      variables: { id: issueId, all: state.fetchAllJournals }
    };
    try {
      await axios[requestType](setUrl, reqBody);
      if (name) {
        await commit("setStoreValue", options);
      }
      await dispatch("fetchJournals", journalsPayload);
      if (payload.commit) {
        const commitPayload = payload.commit.data || options;
        commit(payload.commit.name, commitPayload);
      }
      if (processFunc) {
        processFunc("success", "Success");
      } else {
        await commit("setNotification", { success });
      }
      return true;
    } catch (err) {
      if (processFunc) {
        processFunc("error", err);
      } else {
        commit("setNotification", { err });
      }
      return false;
    }
  },
  async saveProjectStateValue({ state, commit, dispatch }, payload) {
    const { name, url, reqBody, reqType, processFunc } = payload;
    const projectId = state.project.id;
    const defaultUrl = projectQuery + projectId + ".json";
    const defaultReqType = "put";
    const success = state.allLocales.notice_successful_update;
    const setUrl = url || defaultUrl;
    const requestType = reqType || defaultReqType;
    const value =
      typeof payload.value === "object" ? payload.value[name] : payload.value;
    const options = {
      value,
      name,
      toPush: payload.toPush,
      level: "project"
    };
    const journalsPayload = {
      type: "project",
      variables: { id: projectId, allJournals: state.fetchAllJournals }
    };
    try {
      await axios[requestType](setUrl, reqBody);
      await dispatch("fetchJournals", journalsPayload);
      if (name) {
        await commit("setStoreValue", options);
      }
      if (processFunc) {
        processFunc("success", "Success");
      } else {
        await commit("setNotification", { success });
      }
    } catch (err) {
      if (processFunc) {
        processFunc("error", err);
      } else {
        commit("setNotification", { err });
      }
    }
  },
  async fetchStateValue({ commit }, payload) {
    const {
      name,
      apolloQuery,
      processFunc,
      level = "state",
      storeAs = name
    } = payload;
    const response = await apollo.query(apolloQuery);
    const value = processFunc
      ? processFunc(response.data[name])
      : response.data[name];
    const options = {
      name: storeAs,
      value,
      level
    };
    try {
      if (payload.commit) {
        commit(payload.commit, options.value);
      } else {
        commit("setStoreValue", options);
      }
      return response;
    } catch (err) {
      console.log(err);
    }
  },
  async fetchIssueValue({ commit }, payload) {
    const { name, apolloQuery, processFunc } = payload;
    const response = await apollo.query(apolloQuery);
    const value = processFunc
      ? processFunc(response.data.issue[name])
      : response.data.issue[name];
    const options = {
      name,
      value,
      level: "issue"
    };
    try {
      if (payload.commit) {
        commit(payload.commit, options.value);
      } else {
        commit("setStoreValue", options);
      }
    } catch (err) {
      console.log(err);
    }
  },
  async fetchJournals(state, payload) {
    const { variables, type } = payload;
    const response = await apollo.query({
      query: journalsQuery(type, this.state.pluginsList.easyEmojis),
      variables
    });
    const options = {
      value: response.data[type].journals,
      name: "journals",
      level: type
    };
    this.commit("setStoreValue", options);
  },
  async fetchTimeEntries({ state }) {
    const id = state.issue.id;
    const response = await apollo.query({
      query: timeEntriesQuery,
      variables: { id: id }
    });
    const options = {
      value: response.data.issue.timeEntries,
      name: "timeEntries",
      level: "issue"
    };
    this.commit("setStoreValue", options);
  },
  async getFilteredArray(state, payload) {
    // this method needs to use FETCH api instead of apollo, because it returns error that we
    // use same keys for query
    const { query, name } = payload;
    const response = await fetch(`${window.urlPrefix}/graphql.json`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: query })
    });
    const json = await response.json();
    const value = json.data.issue[name];
    const options = {
      value,
      name,
      level: "state"
    };
    this.commit("setStoreValue", options);
  },

  async newIssueValidate({ commit }, payload) {
    let value = payload.value;
    if (payload.hasOwnProperty("id")) {
      value = { id: payload.id, name: payload.value };
    }
    const options = {
      value: value,
      name: payload.name,
      level: "newIssue"
    };
    commit("setStoreValue", options);
  },
  // A graphQl mutation
  // PathToGet & PathToSet - array of nested properties where to set/get a value
  async mutateValue({ commit, state, dispatch }, payload) {
    const {
      apolloMutation,
      pathToGet,
      pathToSet,
      mutationName,
      processFunc,
      noNotification,
      noSuccessNotification
    } = payload;
    const response = await apollo.mutate(apolloMutation);
    let value, options;
    if (pathToGet) {
      value = utils.methods.deepObjectGet(response.data, pathToGet);
    }
    if (pathToSet) {
      options = {
        value,
        level: pathToSet
      };
    }
    if (payload.fetchJournals) {
      const journalsPayload = {
        type: "issue",
        variables: { id: state.issue.id, all: state.fetchAllJournals }
      };
      await dispatch("fetchJournals", journalsPayload);
    }
    const errors = utils.methods.deepObjectGet(response.data, [mutationName])
      .errors;
    const success = state.allLocales.notice_successful_update;
    if (processFunc) {
      let type = "success";
      let message = success;
      if (errors && errors.length) {
        type = "error";
        message = errors;
      }
      processFunc(type, message);
      return response;
    }
    if (noNotification) return response;
    if (errors && errors.length) {
      commit("setNotification", { errors });
    }
    if (!noSuccessNotification) {
      commit("setNotification", { success });
    }
    if (!options) return response;
    if (payload.commit) {
      commit(payload.commit, options.value);
    } else {
      commit("setStoreValue", options);
    }
    return response;
  },
  async validate({ commit, state }, payload) {
    let { processFunc, prop, attrs = {}, ignoreErr = false } = payload;
    const plugins = state.pluginsList;
    const ryses = state.ryses;
    const id = state.issue.id || attrs.id;
    let attributes = state.buffer || attrs;
    const warning = state.allLocales.easy_gantt_errors_save_gantt;
    const success = state.allLocales.notice_successful_update;
    const variables = {
      attributes,
      id
    };
    const response = await apollo.mutate({
      mutation: issueValidate(
        plugins.easySprint,
        plugins.checklists,
        ryses.duration
      ),
      variables
    });
    let message = response.data.issueValidator.errors;
    if (message.length && processFunc) {
      message = message.map(error => {
        return error.fullMessages[0];
      });
      processFunc("error", [ message ]);
      delete state.buffer[prop.name];
      return false;
    } else if (processFunc) {
      const value = response.data.issueValidator.issue;
      processFunc("warning", [ success, warning ]);
      await commit("setPropsByName", value);
      return true;
    } else {
      const value = response.data.issueValidator.issue;
      if (ignoreErr) {
        await commit("setPropsByName", value);
        return true;
      }
      return false;
    }
  }
};

export default actions;
