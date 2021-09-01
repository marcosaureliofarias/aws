import issueSchema from "../graphql/schema";
import userQuery from "../graphql/user";
import quoteValidator from "../graphql/mutations/quoteValidator.js";

export default {
  methods: {
    dateFormatString(time) {
      const allSettings = this.$store.state.allSettings;
      if (!allSettings) return "";
      let rubyFormat = allSettings.date_format;
      rubyFormat = rubyFormat ? rubyFormat : "";
      let format = this.dateFormatter(rubyFormat);
      if (time) {
        const timeString = this.timeFormatString();
        format = format.concat(" ", timeString);
      }
      return format;
    },
    timeFormatString(format) {
      const allSettings = this.$store.state.allSettings;
      if (!allSettings) return "HH:mm";
      const timeFormat = format || allSettings.time_format;
      switch (timeFormat) {
        case "%H:%M":
          return "HH:mm";
        case "%I:%M %p":
        default:
          return "hh:mm a";
      }
    },
    dateFormat(date, withTime) {
      // Format dates for moment.js
      const defaultFormat = this.$store.state.allLocales.date_formats_default;
      if (!date) return "";
      const allSettings = this.$store.state.allSettings;
      let rubyFormat = allSettings?.date_format || defaultFormat;
      let jsFormat = this.dateFormatter(rubyFormat);
      if (withTime) jsFormat += ` ${this.timeFormatString()}`;
      return moment(this.parseDate(date)).format(jsFormat);
    },
    dateFormatter(rubyFormat) {
      switch (rubyFormat) {
        case "%Y-%m-%d":
          return "YYYY-MM-DD";
        case "%Y/%m/%d":
          return "YYYY/MM/DD";
        case "%d/%m/%Y":
          return "DD/MM/YYYY";
        case "%d.%m.%Y":
          return "DD.MM.YYYY";
        case "%d-%m-%Y":
          return "DD-MM-YYYY";
        case "%m/%d/%Y":
          return "MM/DD/YYYY";
        case "%d %b %Y":
          return "DD MMM YYYY";
        case "%d %B %Y":
          return "DD MMMM YYYY";
        case "%b %d, %Y":
          return "MMM DD, YYYY";
        case "%B %d, %Y":
          return "MMMM DD, YYYY";
        default:
          return "D. M. YYYY";
      }
    },
    dateFormatForRequest(date, type, format = "%H:%M") {
      if (!date) return "";
      const timeFormat = this.timeFormatString(format);
      switch (type) {
        case "datetime":
          return moment(date).format("YYYY-MM-DD HH:mm");
        case "time":
          return moment(date).format(timeFormat);
        default:
          return moment(date).format("YYYY-MM-DD");
      }
    },
    dateISOStringParseZone(date) {
      return moment.parseZone(date).toISOString();
    },
    strictDateFormat(date) {
      return moment(date).format("LLLL");
    },
    getFirstDayOfWeek() {
      if (!window.EASY || !window.EASY.datepickerOptions) return 0;
      return window.EASY.datepickerOptions.firstDay;
    },
    deleteItem(name, i) {
      this.$delete(this[`${name}`], i);
    },
    getUserHrefUrl(user) {
      return `/users/${user.id}/profile`;
    },
    getUserAvatarSrc(user) {
      if (!user.avatarUrl) {
        return this.$store.state.defaultAvatarUrl;
      }
      return user.avatarUrl;
    },
    /**
     *
     * @param time {string} "number:number"
     * @returns {null|Date}
     */
    parseTimeForTimePicker(time) {
      if (!time) return null;
      const [hours, minutes] = time.split(":");
      const dateTime = new Date();
      dateTime.setHours(hours, minutes);
      return dateTime;
    },
    isModuleEnabled(name) {
      const enabledModules = this.$store.state.issue.project.enabledModuleNames;
      const enabled = !!enabledModules?.find((element) => element === name);
      return enabled || false;
    },
    // Wrapper - main element where will be scrolling event (class, id, etc.)
    // Id - id of html tag to which you want to scroll (class, id, etc.)
    scrollTo(id) {
      if (!id) return;
      const modal = document.querySelector(".vue-modal__modal-content");
      const element = document.querySelector(`${id}`);
      if (!element) return;
      let topMenuHeight;
      const storeMenuHeight = this.$store.state.topMenuHeight;
      // if top-menu height is computed, set it, otherwise compute it's pixel value
      // and set it to $store
      if (storeMenuHeight) {
        topMenuHeight = storeMenuHeight;
      } else {
        topMenuHeight = this.calculateTopMenuHeight();
        const payload = {
          name: "topMenuHeight",
          value: topMenuHeight,
          level: "state"
        };
        this.$store.commit("setStoreValue", payload);
      }
      const options = {
        top: element.offsetTop - modal.offsetTop - topMenuHeight
      };
      /* Edge is a dumb browser and does not have scroll method,
         so we need to user scrollIntoView fallback without offset */
      if (modal.scroll) {
        modal.scroll(options);
      } else {
        element.scrollIntoView();
      }
    },
    calculateTopMenuHeight() {
      let topMenuHeight = window.ERUI.sassData["topmenu-height"];
      const topMenuHeightInRem = topMenuHeight.match("rem");
      topMenuHeight = parseFloat(topMenuHeight);
      // if top-menu height is in rem, we need to recalculate it to pixels
      if (topMenuHeightInRem) {
        const fontSize = parseFloat(window.ERUI.sassData["font-size"]);
        topMenuHeight = topMenuHeight * fontSize;
      }
      return topMenuHeight || 0;
    },
    copyToClipboard(text) {
      window.easyUtils.clipboard.copy(text);
    },
    getAlignment(e, options, isMobile) {
      options = options || {};
      let { topOffs, rightOffs, bottomOffs, leftOffs } = options;
      topOffs = topOffs || 30;
      let top = !isMobile ? `${topOffs}px` : "";
      // edge is dumb browser so we need to specify default value
      if (e) {
        top = !isMobile ? `${e.target.offsetTop + topOffs}px` : "";
      }
      const alignment = {
        top,
        right: rightOffs ? `${rightOffs}px` : "",
        bottom: bottomOffs ? `${bottomOffs}px` : "",
        left: leftOffs ? `${leftOffs}px` : ""
      };
      return alignment;
    },
    // Method to set a deep obj values.
    // Main - the main object, value - value to set
    // Path - array of nested properties {a: {b :{c: val}}} = ["a", "b", "c"]
    deepObjectSet(main, value, path) {
      if (path.length === 1) {
        const level = path[0];
        main[level] = value;
        return;
      }
      const level = path[0];
      main[level] = !main[level] ? {} : main[level];
      const deepObj = main[level];
      path.splice(0, 1);
      this.deepObjectSet(deepObj, value, path);
    },
    // Method to get a deep obj values.
    // Main - the main object
    // Path - array of nested properties {a: {b :{c: val}}} = ["a", "b", "c"]
    deepObjectGet(main, path) {
      if (path.length === 1) {
        const level = path[0];
        return main[level];
      }
      const level = path[0];
      const deepObj = main[level];
      path.splice(0, 1);
      return this.deepObjectGet(deepObj, path);
    },
    // Builds a custom fields to a choosen dom element - container.
    // Container - ref property value (should be a HTML <form> tag)
    // Classes - extra classes to add
    customFieldsBuilder(options) {
      const { cfArray, container, classes } = options;
      if (!cfArray.length) return;
      classes.wrapper = classes.wrapper ? classes.wrapper : "";
      classes.label = classes.label ? classes.label : "";
      let cfInnerHtml = "";
      const cfContainer = this.$refs[container];
      cfArray.forEach((cf) => {
        const req = cf.customField.isRequired;
        cfInnerHtml += `
          <div class="vue-modal__cf-form-item ${classes.wrapper}">
            <label class="vue-modal__cf-form-item-label ${classes.label} ${req ? "cf-required" : ""
          }">
              ${cf.customField.name} ${req ? "*" : ""}
            </label>
            <div>${cf.editTag}</div>
          </div>
        `;
      });
      $(cfContainer).html(cfInnerHtml);
    },
    // Method to get a values from cf form
    // cfForm - a ref object of a form
    // cfPrefix - same as for graphQl query for cf
    // Will return an object with cf names in a right format for sending to server and their values
    getCFValues(options) {
      const { cfArray, cfForm, cfPrefix } = options;
      const formData = new FormData(cfForm);
      const cfValues = {};
      cfArray.forEach((cf) => {
        const name = `${cfPrefix}[custom_field_values][${cf.customField.id}]`;
        const value = formData.get(name);
        cfValues[cf.customField.id] = value;
      });
      return cfValues;
    },
    wipActivated(value) {
      const payload = {
        name: "wip",
        value,
        level: "state"
      };
      if (value !== this.wip) {
        this.$store.commit("setStoreValue", payload);
        this.wip = !this.wip;
      } else if (this.wip === undefined) {
        this.$store.commit("setStoreValue", payload);
      }
    },
    showByTracker(name) {
      if (!this.$store.state.issue) return true;
      const tracker = this.$store.state.issue.tracker;
      if (!tracker.enabledFields) return;
      return tracker.enabledFields.includes(name);
    },
    async saveValue(eventValue, names, name, valueFunc) {
      let value = {};
      let valueByName;
      let saved = false;
      const inputValue = eventValue.inputValue;
      if (inputValue.hasOwnProperty("id")) {
        valueByName = inputValue.id;
      } else if (inputValue.hasOwnProperty("value")) {
        valueByName = inputValue.value;
      } else {
        valueByName = inputValue;
      }
      if (names) {
        value[names] = valueByName;
      } else {
        value = valueByName;
      }
      const payload = {
        value,
        prop: {
          name: names,
          value: valueByName
        },
        reqBody: {
          issue: value
        },
        reqType: "patch",
        processFunc(type, message) {
          eventValue.showFlashMessage(type, message);
        }
      };
      if (name) {
        payload.name = name;
        value[name] = valueFunc
          ? valueFunc(eventValue, this.$store.state, value[names])
          : eventValue.inputValue;
      }
      if (this.$store.state.localSave) {
        this.addToStoreBuffer(payload);
        !!(await this.$store.dispatch("actionsJudge", payload));
        const toBuffer = true;
        return { saved, toBuffer, payload };
      }
      saved = await this.$store.dispatch("actionsJudge", payload);
      return { saved, payload };
    },
    getValue(eventValue) {
      let value;
      if (eventValue.inputValue.hasOwnProperty("value")) {
        value = eventValue.inputValue.value;
      } else {
        value = eventValue.inputValue;
      }
      return value;
    },
    textilizeBool(bool) {
      const locales = this.$store.state.allLocales;
      return bool ? locales.general_text_yes : locales.general_text_no;
    },
    getTotalRatio(done, all) {
      if (!all) return null;
      const ratio = Math.round((done / all) * 100);
      return ratio;
    },
    workFlowChangable(propName) {
      const issue = this.$store.state.issue;
      if (!issue || !issue.safeAttributeNames) return true;
      return !!issue.safeAttributeNames.find((attr) => attr === propName);
    },
    showMergeRequests() {
      const gitIssue = this.$store.state.issue.easyGitIssue;
      return this.isFeatureEnabled("easy_git") && gitIssue && gitIssue.rows;
    },
    async validateSchema(store) {
      // Fetch schema in case its not in sessionStorage
      const sessionModalSchema = window.sessionStorage.getItem("modal_schema");
      if (!sessionModalSchema) {
        const payload = {
          name: "__type",
          apolloQuery: {
            query: issueSchema
          },
          commit: "schemaValidate"
        };
        await store.dispatch("fetchStateValue", payload);
        window.sessionStorage.setItem(
          "modal_schema",
          JSON.stringify(this.$store.state.__type)
        );
      } else {
        const response = JSON.parse(sessionModalSchema);
        store.commit("schemaValidate", response);
      }
    },
    setInitialState(store) {
      const initialState = {
        name: "initialState",
        value: { ...this.$store.state },
        level: "state"
      };
      store.commit("setStoreValue", initialState);
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
    },
    addToStoreBuffer(obj) {
      const { name, value } = obj.prop;
      const payload = {
        value,
        level: ["buffer", name]
      };
      this.$store.commit("setStoreValue", payload);
      return true;
    },
    isFeatureEnabled(name) {
      const enabledFeatures = this.$store.state.issue.project.enabledFeatures;
      if (!enabledFeatures || !enabledFeatures.length) return true;
      return enabledFeatures.includes(name);
    },
    addHours(date, h) {
      const time = new Date(date);
      time.setTime(time.getTime() + h * 60 * 60 * 1000);
      return time;
    },
    async attendanceApproved(approve, ids, notes) {
      const req = new Request(
        `${window.urlPrefix}/easy_attendances/approval_save.json`
      );
      try {
        const body = {
          ids: ids || [this.attendance.id],
          approve,
          notes
        };
        const options = {
          method: "POST",
          body: JSON.stringify(body),
          headers: {
            "Content-Type": "application/json"
          }
        };
        await fetch(req, options);
      } catch (err) {
        throw new SyntaxError(`attendance Approved error: ${err}`);
      }
    },
    humanizeHashKeyValue(property) {
      const humanized = [...property];
      if (!humanized.length) return [];
      return humanized.map((prop) => {
        return { id: prop.key, name: prop.value };
      });
    },
    getArrayOf(attribute, array) {
      const newAtr = array.map((el) => el[attribute]);
      return newAtr;
    },
    getTimeFromDate(time) {
      const hours = moment(time).hours();
      const minutes = moment(time).minutes();
      return `${hours}:${minutes}`;
    },
    objMerge(targetObj, obj) {
      if (!targetObj && !obj) return;
      Object.keys(targetObj).forEach((key) => {
        // In last condition should check for null bc the value that comes from server can be null
        if (
          typeof obj[key] !== "object" ||
          !targetObj[key] ||
          obj[key] === null
        ) {
          // Check for undefined bc if new object doesnt has same attribute it will be undefined
          // but it can be null or empty string
          if (obj[key] === undefined || targetObj[key] === obj[key]) return;
          targetObj[key] = obj[key];
        } else {
          this.objMerge(targetObj[key], obj[key]);
        }
      });
      return targetObj;
    },
    mergeInjectedIssue(target, obj) {
      let value = target;
      if (obj) {
        value = this.objMerge(target, obj);
      }
      const payload = {
        name: "issue",
        value,
        level: "state"
      };
      this.$store.commit("setStoreValue", payload);
    },
    // Get time and date as arguments
    // Usefull for timepickers where need to change a date and save time
    moveDate(date, time) {
      if (!date) {
        return moment(time).format("YYYY-MM-DD");
      }
      const newDate = moment(time);
      const momentDate = moment(date).date();
      newDate.date(momentDate);
      return moment(newDate).format("YYYY-MM-DD HH:mm");
    },
    parseDate(date) {
      if (window.EASY?.utils?.parseDate) {
        return EASY.utils.parseDate(date);
      }
      // eslint-disable-next-line
      console.error("You don't have access to a function: EASY.utils.parseDate");
      return new Date(date);
    },
    parseTimezone(date) {
      const FORMAT = "YYYY-MM-DD HH:mm";
      if (!date) return moment().format(FORMAT);
      return moment(date).format(FORMAT);
    },
    showBackdrop(show) {
      const payload = {
        name: "backdrop",
        value: show,
        level: "state"
      };
      this.$store.commit("setStoreValue", payload);
    },
    recountDate(form, toUpdate, changed, isAdding) {
      const changedValue = form[changed];
      if (!changedValue) return;
      const countedDate = isAdding
        ? moment(changedValue).add(form.usermonths, "months")
        : moment(changedValue).subtract(form.usermonths, "months");
      form[toUpdate] = moment(countedDate).isValid()
        ? moment(countedDate).format()
        : null;
    },
    validate(ref) {
      let res = false;
      this.$refs[ref].validate((valid) => (res = valid));
      return res;
    },
    async getAvailableVariables(id) {
      let variables = { attributes: {} };
      if (id) {
        variables.attributes.easy_crm_case_id = id;
      }
      const mutationPayload = {
        mutationName: "easyPriceBookQuoteValidator",
        apolloMutation: {
          mutation: quoteValidator,
          variables: variables
        },
        noSuccessNotification: true
      };
      const { data } = await this.$store.dispatch(
        "mutateValue",
        mutationPayload
      );
      return data.easyPriceBookQuoteValidator.easyPriceBookQuote;
    },
    setOldModalsStyle(displayStyle) {
      // if new vue modal is opened from old modal, we need to hide/show old modals
      // to be able to click into inputs of new modal
      const oldModals = document.querySelectorAll(".ui-dialog.modal");
      if (!oldModals) return;
      oldModals.forEach((modal) => {
        modal.style.display = displayStyle;
      });
    },
    prepareLabelClass({bem, block, required}) {
      const requiredClass = required ? "required" : "";
      return bem.ify(block, "form-item-label", requiredClass);
    },
  }
};
