<template>
  <span
    ref="inputWrapper"
    :class="
      `${activeClasses} ${multipleClass} editable-input__wrapper ${permissionClasses} ${inputStateClass}`
    "
    @focusin="setEdit()"
    @focusout="setShow()"
  >
    <template v-if="!showSpan">
      <v-select
        v-if="data.inputType === 'autocomplete'"
        ref="v-select"
        v-model="input"
        :filterable="data.filterable"
        :options="getOptions()"
        :placeholder="$props.data.placeholder"
        :multiple="multiple"
        :searchable="$props.searchable"
        :disabled="!$props.data.editable"
        :get-option-key="option => option.name"
        :get-option-label="option => option.name || option.value || option.id"
        :selectable="option => !option.disabled"
        label="value"
        @search:focus="fetchOptions"
        @search:blur="searchBlur"
        @search="fetchOptions"
        @input="saveAndCreateActivity($event)"
      >
        <template slot="loading">{{ allLocales.label_loading }}</template>
        <template slot="no-options">{{ allLocales.label_no_data }}</template>
        <template slot="option" slot-scope="option">
          {{ showOption(option) }}
          {{
            option.disabled
              ? allLocales.easy_page_module_resource_availability_label_unavailable
              : ""
          }}
          <!-- Attendance status -->
          <span
            v-if="!!attendanceStatus(option)"
            :class="getAttendanceCss(option)"
          >
            {{ attendanceStatus(option) }}
          </span>
        </template>
        <template slot="selected-option" slot-scope="option">
          {{ showOption(option) }}
          <span
            v-if="!!attendanceStatus(option)"
            :class="getAttendanceCss(option)"
          >
            {{ attendanceStatus(option) }}
          </span>
        </template>
      </v-select>

      <div v-else-if="isDate" class="vdatetime_wrapper">
        <datetime
          v-model="date"
          :format="format"
          :type="data.inputType"
          :auto="true"
          :lang="datepickerOverrides"
          :show-time-panel="showTimePanel"
          :range="data.range"
          :disabled="data.disabled"
          :disabled-time="() => false"
          :minute-step="minuteStep"
          :clearable="clearable"
          popup-class="excluded"
          @close="onDateTimeClose"
          @clear="onDateTimeClose"
          @open="onDateTimeOpen"
        >
          <template v-if="data.range" v-slot:header="{ emit }">
            <span class="mx-datepicker-selected">
              {{ timePanelDates.from }} ~
              {{ timePanelDates.to }}
            </span>
          </template>
          <template v-slot:footer="{ emit }">
            <div>
              <button
                v-if="showTimeButton"
                class="mx-btn mx-btn-text"
                @click="showTimePanel = true"
              >
                {{ allLocales.button_select_time }}
              </button>
              <button
                v-else-if="showDateButton"
                class="mx-btn mx-btn-text"
                @click="showTimePanel = false"
              >
                {{ allLocales.button_select_date }}
              </button>
              <button
                v-if="showSaveButton"
                class="mx-btn mx-btn-text"
                @click="saveDatepicker(emit)"
              >
                {{
                  customLabels && customLabels.datepickerConfirmLabel
                    ? customLabels.datepickerConfirmLabel
                    : allLocales.button_save
                }}
              </button>
            </div>
          </template>
        </datetime>
      </div>
      <div v-else-if="isBool" class="bool__wrapper">
        <template v-if="$props.data.tagStyle === 'check_box'">
          <label class="bool__label--checkbox">
            <input
              v-model="checkboxInput"
              :disabled="!$props.data.editable"
              type="checkbox"
              @change="saveAndCreateActivity"
            />
          </label>
        </template>
        <template v-else>
          <label v-for="(radio, i) in radioButtons" :key="i">
            <input
              v-model="inputValue"
              type="radio"
              :disabled="!$props.data.editable"
              :name="uniqueRadioID"
              :value="radio.id"
              @change="saveAndCreateActivity"
            />
            {{ radio.name }}
          </label>
        </template>
        <!--  Flash notice  -->
        <div
          v-if="flashMessageType"
          class="editable-input__notice"
          :class="flashMessageClass"
        >
          <ul>
            <li v-for="(message, i) in flashMessages" :key="i">
              {{ message }}
            </li>
          </ul>
        </div>
      </div>
      <input
        v-else
        ref="focusableInput"
        v-model="input"
        type="text"
        :placeholder="placeholder"
        @blur="saveAndCreateActivity"
        @keyup.enter="$event.target.blur()"
        @input="changeInput"
      />
    </template>

    <!--  Show span instead of input if setting enabled  -->
    <span
      v-else
      class="vue-modal__headline--static excluded"
      @click="changeSpanToInput"
    >
      <a
        v-if="data.withLink && data.link"
        :href="data.link"
        :title="value"
        target="_blank"
      >
        {{ value }}
      </a>
      <template v-else>
        {{ textilizeSpanData() }}
      </template>
    </span>

    <!--  Grey backdrop  -->
    <span class="editable-input__backdrop" />

    <!--  Flash notice  -->
    <div
      v-if="loading && !flashMessages.length"
      class="editable-input__loader"
    />
    <div
      v-if="flashMessageType"
      class="editable-input__notice"
      :class="flashMessageClass"
    >
      <ul>
        <li v-for="(message, i) in flashMessages" :key="i">
          {{ message }}
        </li>
      </ul>
    </div>
    <!--  hidden input with value and name for form serialization  -->
    <input type="hidden" :name="name" :value="hiddenInputVal" />
  </span>
</template>

<script>
import { isPlainObject } from "lodash";

export default {
  name: "InlineInput",
  props: {
    data: Object,
    value: [String, Number, Object, Array, Boolean],
    formattedValue: [String, Number, Object, Array],
    optionsArray: [Boolean, Array],
    id: [String, Number],
    filterable: Boolean,
    searchable: {
      type: Boolean,
      default: () => true
    },
    lazy: {
      type: Boolean,
      default: () => false
    },
    multiple: {
      type: Boolean,
      default: () => false
    },
    dateProp: {
      type: [String, Object, Array, Date, Boolean],
      default: () => ""
    },
    errorMessages: {
      type: Array,
      default: () => null
    },
    errorType: {
      type: String,
      default: () => null
    },
    withLoading: {
      type: Boolean,
      default: () => true
    },
    required: {
      type: Boolean,
      default: () => false
    },
    name: {
      type: String,
      default: ""
    }
  },
  data() {
    return {
      options: null,
      loading: false,
      activeClasses: "",
      showClasses: "",
      editClasses: "",
      edit: false,
      placeholder: this.$props.data.hasOwnProperty("placeholder")
        ? this.$props.data.placeholder
        : this.$props.data.labelName,
      selectOptions: this.$props.optionsArray,
      inputValue: this.$props.value,
      oldValue: this.$props.value,
      highlighted: this.$store.state.highlighted,
      messageType: null,
      messages: "",
      timer: null,
      date: this.getDate(this.dateProp),
      timerInput: null,
      timerIsOn: false,
      allLocales: this.$store.state.allLocales,
      spanToInput: true,
      showTimePanel: false,
      minuteStep: 15,
      uniqueRadioID: `${+new Date()}_${this.id}`, // Create unique ID for radiobutton name based on prop id
      searchTimeout: null,
      datetimeOpened: false,
      datepickerOverrides: {
        formatLocale: this.getDatepickerFormat()
      }
    };
  },
  computed: {
    input: {
      get() {
        return this.$props.value;
      },
      set(value) {
        this.inputValue = value;
      }
    },
    hiddenInputVal() {
      if (this.$props.data.tagStyle === "check_box") {
        return this.input ? "1" : "0";
      }
      return this.input;
    },
    flashMessages() {
      return this.$props.errorMessages && this.$props.errorMessages.length
        ? this.$props.errorMessages
        : this.messages;
    },
    flashMessageType() {
      return this.$props.errorType ? this.$props.errorType : this.messageType;
    },
    flashMessageClass() {
      const messageClasses = {
        error: "editable-input__notice--error",
        warning: "editable-input__notice--warning"
      };
      const msgClass = messageClasses[this.flashMessageType];
      if (!msgClass) return "";
      return msgClass;
    },
    permissionClasses() {
      return this.data.editable ? "" : "no-hover";
    },
    inputStateClass() {
      let result = !this.input;
      switch (this.$props.data.inputType) {
        case "bool":
          result = false;
          break;
        case "list":
        case "country_select":
        case "enumeration":
        case "value_tree":
        case "user":
        case "version":
        case "autocomplete":
        case "easy_lookup":
          result =
            !this.input ||
            this.input.length == 0 ||
            (this.input.length == 1 && this.input[0] == null);
          break;
        case "date":
        case "time":
        case "datetime":
          result = !this.data.date;
          break;
      }

      const hasValue = result ? "" : "u-hasValue";
      const required = this.$props.required ? "required" : "";
      return `${hasValue} ${required}`;
    },
    showSpan() {
      return (
        !this.$props.data.editable ||
        (this.$props.data.withSpan && this.spanToInput)
      );
    },
    unit() {
      if (
        !this.data ||
        !this.data.unit ||
        this.value === null ||
        !this.value.length
      )
        return "";
      return this.data.unit;
    },
    isDate() {
      const inputType = this.$props.data.inputType;
      const allowedTypes = ["date", "datetime", "time"];
      return allowedTypes.some(type => type === inputType);
    },
    format() {
      const inputType = this.data.inputType;
      if (inputType === "time") return this.timeFormatString();
      return this.dateFormatString(inputType === "datetime");
    },
    isBool() {
      const inputType = this.$props.data.inputType;
      return inputType === "bool";
    },
    radioButtons() {
      const fallbackButtons = [
        { id: "", name: `(${this.allLocales.label_none})` },
        { id: "1", name: this.allLocales.general_text_yes },
        { id: "0", name: this.allLocales.general_text_no }
      ];
      return this.data.radioButtons || fallbackButtons;
    },
    checkboxInput: {
      get() {
        // backend sends data in format "0"/"1" instead of false/true
        // so we need to change value to be false/true because in JS is "0" => true
        return !!+this.$props.value;
      },
      set(val) {
        this.inputValue = val;
      }
    },
    clearable() {
      const clearable = this.$props.data.clearable;
      // Check for undefined bc for almpst all entities clearable is not set at all
      if (clearable || clearable === undefined) {
        return true;
      }
      return false;
    },
    showTimeButton() {
      return !this.showTimePanel && this.data.inputType === "datetime";
    },
    showDateButton() {
      return this.showTimePanel && this.data.inputType === "datetime";
    },
    showSaveButton() {
      const types = ["datetime", "time"];
      return types.find(el => el === this.data.inputType);
    },
    multipleClass() {
      const multClass = this.$props.multiple ? "multiple" : "";
      return multClass;
    },
    timePanelDates() {
      const dateFrom = this.date[0];
      const dateTo = this.date[1];
      const inputType = this.$props.data.inputType;
      const withTime = inputType === "datetime" || inputType === "time";
      return {
        from: this.dateFormat(dateFrom, withTime),
        to: this.dateFormat(dateTo, withTime)
      };
    },
    customLabels() {
      return this.$props.data.customLabels;
    }
  },
  watch: {
    dateProp: {
      handler(newValue) {
        this.date = this.getDate(newValue);
      }
    }
  },
  mounted() {
    this.setClasses();
  },
  methods: {
    saveDatepicker(emit) {
      this.changeSelectedRange();
      emit && emit(this.date);
    },
    textilizeSpanData() {
      if (this.formattedValue) {
        return `${this.formattedValue} ${this.unit}`;
      }
      if (this.input) {
        if (typeof this.input === "object") {
          return this.showOption(this.input);
        }
        return `${this.input} ${this.data.unit || ""}`;
      }
      let textilizedOutput = "";
      switch (this.data.inputType) {
        case "autocomplete":
          textilizedOutput = this.value.hasOwnProperty("name")
            ? this.value.name
            : this.value;
          break;
        case "date":
          if (this.data.range) {
            textilizedOutput = this.textilizeRangeDate();
          } else {
            textilizedOutput = `${this.dateFormat(this.data.date)}`;
          }
          break;
        case "datetime":
          if (this.data.range) {
            textilizedOutput = this.textilizeRangeDate(true);
          } else {
            textilizedOutput = `${this.dateFormat(this.data.date, true)}`;
          }
          break;
        case "time": {
          textilizedOutput = this.dateFormatForRequest(
            this.parseDate(this.dateProp),
            "time",
            "default"
          );
          break;
        }
        case "text":
        case "number":
        default:
          textilizedOutput = `${this.value || ""} ${this.unit}`;
          break;
      }
      return textilizedOutput;
    },
    textilizeRangeDate(withTime) {
      const firstDate = this.dateFormat(this.data.date[0], withTime);
      const secondDate = this.dateFormat(this.data.date[1], withTime);
      return `${firstDate} ~ ${secondDate}`;
    },
    getOptions() {
      if (!this.$props.optionsArray) return this.options;
      return this.$props.optionsArray;
    },
    changeSpanToInput() {
      if (!this.$props.data.editable) return;
      if (this.$props.data.showPopUp) return;
      this.spanToInput = false;
      this.$nextTick(this.focusInput);
    },
    changeInput() {
      if (this.$props.lazy) {
        if (this.timerInput) {
          clearTimeout(this.timerInput);
          this.timerInput = null;
        }
        this.timerInput = setTimeout(() => {
          this.$emit("child-value-input", {
            inputValue: this.inputValue
          });
        }, 800);
      } else {
        this.$emit("child-value-input", {
          inputValue: this.inputValue
        });
      }
    },
    focusInput() {
      this.$refs.focusableInput.focus();
    },
    showOption(option) {
      if (option.name) {
        return option.name;
      } else if (option.text) {
        return option.text;
      } else if (option.value) {
        return option.value;
      } else {
        return null;
      }
    },
    attendanceStatus(option) {
      return option.attendance_status || option.attendanceStatus;
    },
    getAttendanceCss(option) {
      return option.attendance_status_css || option.attendanceStatusCss;
    },
    async fetchOptions(search, loading) {
      if (this.$props.data.filterable && this.$props.data.optionsArray) return;
      if (this.$props.optionsArray.length > 0) {
        this.options = this.$props.optionsArray;
      }
      clearInterval(this.searchTimeout);
      this.searchTimeout = setTimeout(
        this.getSetOptions.bind(null, search, loading),
        500
      );
    },
    async getSetOptions(search, loading) {
      if (loading) loading(true);
      if (this.$props.data.searchQuery) {
        this.options = await this.$props.data.searchQuery(
          this.$props.id,
          search,
          this.$props.data.fetchItemName
        );
      }
      if (this.data.firstOptionEmpty) {
        this.handleFirstEmptyOption();
      }
      if (loading) loading(false);
      this.$nextTick(this.resizeAutocompleteDropdown);
    },
    handleFirstEmptyOption() {
      if (!this.options) return;
      const optionIsObject = this.options.length ? isPlainObject(this.options[0]) : false;
      const firstEmptyPresent = this.options.some(option => {
        if (!optionIsObject) return !option;
        return !option.name && !option.value;
      });

      if (!firstEmptyPresent) {
        const emptyValue = optionIsObject ? { name: "", value: "" } : "";
        this.options.unshift(emptyValue);
      }
    },
    resizeAutocompleteDropdown() {
      const STATICSPACE = 10;
      // Get all elements
      const ref = this.$refs["v-select"];
      if (!ref) return;
      const dropdownEl = ref.$el;
      const dropdownToggle = dropdownEl.querySelector(".vs__dropdown-toggle");
      const dropdownMenu = document.querySelector("body > .vs__dropdown-menu");
      const modal = document.querySelector(".vue-modal");
      // Get dimensions
      if (!dropdownMenu || !modal) return;
      const dropdownMenuDim = dropdownMenu.getBoundingClientRect();
      const modalDim = modal.getBoundingClientRect();

      // Check if opened autocomplete dropdown is bigger thank modal and if so, resize it
      if (dropdownMenuDim.bottom + STATICSPACE > modalDim.bottom) {
        const gap = dropdownMenuDim.bottom - modalDim.bottom;
        const properHeight =
          dropdownMenuDim.height - gap - dropdownToggle.offsetHeight;
        dropdownMenu.style.height = `${properHeight}px`;
      }
    },
    async setEdit(focusAfter = false) {
      if (!this.$props.data.editable) return;
      this.edit = true;
      this.activeClasses = this.editClasses;
      if (focusAfter) {
        await this.$nextTick();
        this.focusInput();
      }
    },
    setShow() {
      if (this.data.datetimeOpened) return;
      this.edit = false;
      this.activeClasses = this.showClasses;
    },
    saveAndCreateActivity() {
      if (this.inputValue === null) return;
      this.spanToInput = true;
      this.setShow();
      if (this.data.inputType === "autocomplete" && this.inputValue === this.$props.value) return;
      if (this.data.inputType !== "autocomplete" && this.inputValue === this.oldValue) return;
      this.changeSelectedValue();
      this.oldValue = this.inputValue;
      this.$emit("child-value-change", {
        inputValue: this.inputValue,
        showFlashMessage: this.showFlashMessage
      });
      if (this.$props.withLoading) {
        this.loading = true;
      }
    },
    changeSelectedRange() {
      let formattedDate = "";
      if (this.data.range) {
        const copy = this.date;
        const parsed = copy.map(date =>
          this.dateFormatForRequest(date, this.$props.data.inputType)
        );
        formattedDate = parsed;
        const copyOldVal = this.oldValue || this.$props.dateProp;
        this.oldValue = copyOldVal.map(date =>
          this.dateFormatForRequest(date, this.$props.data.inputType)
        );
      } else {
        formattedDate = this.dateFormatForRequest(
          this.date,
          this.$props.data.inputType
        );
        this.oldValue = this.dateFormatForRequest(
          this.$props.dateProp,
          this.$props.data.inputType
        );
      }
      this.oldValue = this.oldValue || this.$props.dateProp;
      if (!this.oldValue) this.oldValue = "";
      // JSON stringify is because we test equality of arrays sometimes (e.g. datepicker range)
      if (
        JSON.stringify(this.oldValue) === JSON.stringify(formattedDate) &&
        !this.flashMessages
      )
        return;
      if (this.$props.withLoading) {
        this.loading = true;
      }
      this.inputValue = this.date;
      this.$emit("child-value-change", {
        inputValue: formattedDate,
        showFlashMessage: this.showFlashMessage
      });
      this.oldValue = formattedDate;
    },
    setClasses() {
      if (!this.$props.data.classes) return;
      const { show: showClasses } = this.$props.data.classes;
      const { edit: editClasses } = this.$props.data.classes;
      this.editClasses = editClasses;
      this.activeClasses = this.showClasses = showClasses;
    },
    changeSelectedValue() {
      if (Array.isArray(this.inputValue)) {
        this.inputValue = this.inputValue.map(person =>
          this.replaceUserNamesAndIds(person)
        );
        return;
      }
      const inputValue = this.replaceUserNamesAndIds(this.inputValue);
      this.inputValue = Array.isArray(inputValue.length)
        ? inputValue[0]
        : inputValue;
    },
    replaceUserNamesAndIds(entity) {
      const excludedNames = ["<< Last assignee >>", "<< me >>", "<< Author >>"];
      const name = entity.name || entity.value;
      const isInExcluded = excludedNames.includes(name);
      const allUsers = this.$store.state.allUsers;
      if (!allUsers || !allUsers.length || !isInExcluded) return entity;
      const replacedUser = allUsers.filter(
        user =>
          (+user.id === +entity.id || +user.id === +entity.value) &&
          !excludedNames.includes(user.name)
      );
      return replacedUser[0] || entity;
    },
    getDate(date) {
      if (!date) return "";
      const inputType = this.$props.data.inputType;
      const dateTypes = ["date", "datetime", "time"];
      if (!dateTypes.includes(inputType)) return;
      if (inputType === "datetime") {
        return this.parseDate(`${date}Z`);
      }
      if (!this.data.range) {
        return this.parseDate(date);
        // return this.dateISOStringParseZone(this.$props.data.date);
      } else {
        const copy = date;
        const parsed = copy.map(date => this.parseDate(date));
        return parsed;
      }
    },
    showFlashMessage(type, message) {
      const attribute = this.$props.data.attribute;
      this.loading = false;
      this.messageType = type;
      if (type === "success") {
        this.messages = [message];
        this.timer = setTimeout(() => {
          this.messageType = null;
        }, 2000);
        return;
      }
      if (message.length && Array.isArray(message)) {
        this.messages = [];
        message.forEach(msg => {
          if (msg.attribute) {
            if (attribute && msg.attribute !== attribute && message.length > 1) return;
            if (msg && msg.fullMessages && msg.fullMessages.length) {
              const messages = msg.fullMessages.map(fullMsg => fullMsg);
              this.messages.push(messages);
            }
          } else {
            this.messages.push(msg);
          }
        });
        this.messages = this.messages.flat();
        return;
      }
      if (!message.hasOwnProperty("response")) {
        this.messages = message;
        return;
      }
      this.messages = message.response ? message.response.data.errors : message;
    },
    onDateTimeOpen() {
      this.data.datetimeOpened = true;
    },
    onDateTimeClose() {
      this.data.datetimeOpened = false;
      this.setShow();
      this.changeSelectedRange(this.data.labelName);
    },
    getDatepickerFormat() {
      const locales = this.$store.state.allLocales;
      if (!locales)
        return {
          firstDayOfWeek: this.getFirstDayOfWeek(),
          firstWeekContainsDate: 4
        };
      return {
        firstDayOfWeek: this.getFirstDayOfWeek(),
        firstWeekContainsDate: 4,
        months: JSON.parse(
          locales.date_standalone_month_names.replace("nil, ", "")
        ).slice(-12),
        // MMM
        monthsShort: JSON.parse(
          locales.date_abbr_month_names.replace("nil, ", "")
        ).slice(-12),
        // dddd
        weekdays: JSON.parse(
          locales.date_day_names.replace("nil, ", "")
        ).slice(-7),
        // ddd
        weekdaysShort: JSON.parse(
          locales.date_abbr_day_names.replace("nil, ", "")
        ).slice(-7),
        // dd
        weekdaysMin: JSON.parse(
          locales.date_abbr_day_names.replace("nil, ", "")
        ).map(el => el.slice(0, 2)).slice(-7)
      };
    },
    searchBlur() {
      this.$emit("search:blur");
      this.$refs["v-select"].search = "";
    }
  }
};
</script>
