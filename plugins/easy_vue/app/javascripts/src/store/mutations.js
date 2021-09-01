import utils from "../mixins/utils";

const mutations = {
  setStoreValue(state, options) {
    const { name, value, toPush, level } = options;
    let setLevel = state;
    if (level !== "state") {
      setLevel = state[level];
    }
    const excluded = [
      "state",
      "issue",
      "project",
      "onPremiseApplication",
      "easyMeeting",
      "newIssue",
      "newMeeting"
    ];
    if (!excluded.includes(level)) {
      setLevel = state;
      utils.methods.deepObjectSet(setLevel, value, level);
      return;
    }
    if (toPush) {
      setLevel[name].push(value);
    } else {
      setLevel[name] = {};
      setLevel[name] = value;
    }
  },
  schemaValidate(state, data) {
    const issueFields = data.fields;
    const plugins = state.pluginsList;
    const ryses = state.ryses;
    if (!plugins || !ryses) return;
    Object.keys(plugins).forEach(plugin => {
      const enabled = !!issueFields.find(field => plugin === field.name);
      if (enabled) {
        plugins[plugin] = enabled;
      }
    });
    Object.keys(ryses).forEach(rys => {
      const enabled = !!issueFields.find(field => rys === field.name);
      if (enabled) {
        ryses[rys] = enabled;
      }
    });
    state.__type = data;
  },
  setChecklistsItemTitle(state, data) {
    const checklist = state.issue.checklists.find(
      checklist => checklist.id === data.list.id
    );
    if (checklist) {
      checklist.easyChecklistItems.forEach(item => {
        if (item.id === data.item.id) {
          item.subject = data.subject;
          item.done = data.item.isDone;
          return;
        }
      });
    }
  },
  setChecklist(state, data) {
    const checklist = state.issue.checklists.find(
      checklist => checklist.id === data.list.id
    );
    if (checklist) {
      checklist.name = data.name;
    }
  },
  setNotification(state, respond) {
    if (respond.success && respond.success.delete) {
      state.notification = "";
      return;
    }
    let type;
    let text = "";
    if (respond.err) {
      type = "vue-error";
      text = respond.err.response
        ? respond.err.response.data.errors[0]
        : respond.err.message;
    } else if (respond.errors && respond.errors.length) {
      type = "vue-error";
      respond.errors.forEach(error => {
        let user = "";
        if (respond.errors.length > 1 && error.user) {
          user = `(${error.user.name})` || "";
        }
        if (!error.fullMessages) {
          text += `${error} ${user}<br>`;
        } else {
          text += `${error.fullMessages.map(el => el)} ${user}<br>`;
        }
      });
    } else {
      type = "success";
      text = respond.success;
    }
    const notification = {
      type,
      text
    };
    state.notification = notification;
  },
  setAdditionalData(state, additionalData) {
    state.issue = { ...state.issue, ...additionalData };
    if (additionalData.attachments) {
      state.attachments = additionalData.attachments;
    }

    const requiredCustomValuesToFill = state.issue.customValues.filter(
      customVal => {
        const firstValNull =
          customVal.value &&
          customVal.value.length &&
          customVal.value[0] === null;
        return (
          customVal.customField.isRequired && (!customVal.value || firstValNull)
        );
      }
    );

    state.issue = {
      ...state.issue,
      requiredCustomValuesToFill
    };

    state.additionalDataFetched = true;
  },
  setPropsByName(state, payload) {
    state.issue = { ...state.issue, ...payload };
  }
};

export default mutations;
