<template>
  <div class="vue-modal__repeating-advanced">
    <h4 class="vue-modal__heading--popup popup-heading">
      {{ translations.title_easy_repeating_advanced_header }}
    </h4>
    <div class="vue-modal__repeating-advanced__scaffold">
      <div class="vue-modal__attribute vue-modal__attribute--rep-1">
        <span class="vue-modal__attribute__boxes-wrapper">
          <label>
            <input v-model="easyRepeatSettings.period" value="daily" type="radio" />
            {{ translations.label_easy_issue_easy_repeating_period_daily }}
          </label>
          <label>
            <input
              v-model="easyRepeatSettings.period"
              value="weekly"
              type="radio"
            />
            {{ translations.label_easy_issue_easy_repeating_period_weekly }}
          </label>
          <label>
            <input
              v-model="easyRepeatSettings.period"
              value="monthly"
              type="radio"
            />
            {{ translations.label_easy_issue_easy_repeating_period_monthly }}
          </label>
          <label>
            <input
              v-model="easyRepeatSettings.period"
              value="yearly"
              type="radio"
            />
            {{ translations.label_easy_issue_easy_repeating_period_yearly }}
          </label>
        </span>
        <label class="vue-modal__attribute-label">
          {{ translations.label_easy_issue_easy_is_repeating }}
        </label>
      </div>
      <div v-if="showDailyOption" class="vue-modal__attribute vue-modal__attribute--rep-3">
        <p>
          <input
            v-model="easyRepeatSettings.daily_option"
            value="each"
            type="radio"
          />
          <span class="editable-input__wrapper l__w--auto">
            <input
              v-model="easyRepeatSettings.daily_each_x"
              type="number"
              min="1"
              max="31"
              size="3"
              class="l__w--auto"
            />
          </span>
          {{ translations.label_easy_issue_easy_reccuring_daily_each }}
        </p><br />
        <p>
          <input
            v-model="easyRepeatSettings.daily_option"
            value="work"
            type="radio"
          />
          <span class="editable-input__wrapper l__w--auto">
            <input
              v-model="easyRepeatSettings.daily_work_x"
              type="number"
              min="1"
              max="31"
              size="3"
              class="l__w--auto"
            />
          </span>
          {{ translations.label_easy_issue_easy_reccuring_daily_work }}
        </p>
        <label class="vue-modal__attribute-label">
          {{ translations.label_easy_issue_easy_reccuring_daily_every }}
        </label>
      </div>
      <div v-if="showWeeklyOption" class="vue-modal__attribute vue-modal__attribute--rep-3">
        <span class="vue-modal__attribute__boxes-wrapper">
          <label v-for="(day, i) in daysInWeek" :key="i">
            <input
              v-model="easyRepeatSettings.week_days"
              :value="i"
              type="checkbox"
            />
            {{ day }}
          </label>
        </span>
        <label class="vue-modal__attribute-label">
          {{ translations.label_easy_is_easy_repeating_period }}
        </label>
      </div>
      <div v-if="showMonthlyOption" class="vue-modal__attribute vue-modal__attribute--rep-2">
        <p>
          <input
            v-model="easyRepeatSettings.monthly_option"
            value="xth"
            type="radio"
          />
          {{ translations.label_easy_is_easy_repeating_endtype_date }}
          <span class="editable-input__wrapper l__w--auto">
            <input
              v-model="easyRepeatSettings.monthly_day"
              type="number"
              min="1"
              max="31"
              class="l__w--auto"
            />
          </span>
        </p><br />
        <p>
          <input
            v-model="easyRepeatSettings.monthly_option"
            value="custom"
            type="radio"
            class="l__w--auto"
          />
          <CustomOrderSelect
            :translations="translations"
            :custom-order-value="easyRepeatSettings.monthly_custom_order"
            @change="val => (easyRepeatSettings.monthly_custom_order = val)"
          />
          <WeekDaysSelect
            :translations="translations"
            :week-day-value="easyRepeatSettings.monthly_custom_day"
            @change="val => (easyRepeatSettings.monthly_custom_day = val)"
          />
        </p>
        <label class="vue-modal__attribute-label">
          {{ translations.label_easy_is_easy_repeating_period }}
        </label>
      </div>
      <div v-if="showMonthlyOption" class="vue-modal__attribute vue-modal__attribute--rep-4">
        <span class="editable-input__wrapper l__w--auto">
          <input
            v-model="easyRepeatSettings.monthly_period"
            type="number"
            min="1"
            max="12"
            class="l__w--auto"
          />
        </span>
        {{ translations.label_easy_issue_easy_reccuring_recur_months }}
        <label class="vue-modal__attribute-label">
          {{ translations.label_easy_issue_easy_reccuring_daily_every }}
        </label>
      </div>
      <div v-if="showYearlyOption" class="vue-modal__attribute vue-modal__attribute--rep-2">
        <p>
          <input
            v-model="easyRepeatSettings.yearly_option"
            value="date"
            type="radio"
          />
          {{ translations.label_easy_is_easy_repeating_endtype_date }}
          <YearsSelect
            :year-value="easyRepeatSettings.yearly_month"
            :translations="translations"
            @change="val => (easyRepeatSettings.yearly_month = val)"
          />
          <span class="editable-input__wrapper l__w--auto">
            <input
              v-model="easyRepeatSettings.yearly_day"
              type="number"
              min="1"
              max="31"
              class="l__w--auto"
            />
          </span>
        </p><br />
        <p>
          <input
            v-model="easyRepeatSettings.yearly_option"
            value="custom"
            type="radio"
          />
          <CustomOrderSelect
            :translations="translations"
            :custom-order-value="easyRepeatSettings.yearly_custom_order"
            @change="val => (easyRepeatSettings.yearly_custom_order = val)"
          />
          <WeekDaysSelect
            :translations="translations"
            :week-day-value="easyRepeatSettings.yearly_custom_day"
            @change="val => (easyRepeatSettings.yearly_custom_day = val)"
          />
          <YearsSelect
            :year-value="easyRepeatSettings.yearly_custom_month"
            :translations="translations"
            @change="val => (easyRepeatSettings.yearly_custom_month = val)"
          />
        </p>
        <label class="vue-modal__attribute-label">
          {{ translations.label_easy_is_easy_repeating_period }}
        </label>
      </div>
      <div v-if="showYearlyOption" class="vue-modal__attribute vue-modal__attribute--rep-4">
        <span class="editable-input__wrapper l__w--auto">
          <input
            v-model="easyRepeatSettings.yearly_period"
            type="number"
            min="1"
            max="12"
            class="l__w--auto"
          />
        </span>
        {{ translations.label_easy_issue_easy_reccuring_recur_years }}
        <label class="vue-modal__attribute-label">
          {{ translations.label_easy_issue_easy_reccuring_recur_every }}
        </label>
      </div>
    </div>

    <hr />

    <Collapsible :block="bem.block" :default-opened="false">
      <template v-slot:header>
        {{ translations.label_easy_repeating_time_section_heading }}
      </template>
      <template v-slot:body>
        <div class="vue-modal__repeating-advanced__scaffold">
          <div class="vue-modal__attribute vue-modal__attribute--rep-1">
            <InlineInput
              :data="{
                inputType: 'date',
                editable: true,
                withSpan: false,
                date: easyRepeatSettings.easy_next_start
              }"
              :with-loading="false"
              class="l__w--auto"
              @child-value-change="e => handleDatepicker(e, 'easy_next_start')"
            />
            <label class="vue-modal__attribute-label">
              {{ translations.field_start_time }}
            </label>
          </div>
          <div class="vue-modal__attribute vue-modal__attribute--rep-2">
            <p>
              <label>
                <input
                  v-model="easyRepeatSettings.endtype"
                  value="date"
                  type="radio"
                />
                {{ translations.label_easy_is_easy_repeating_endtype_date }}
                <InlineInput
                  id="end_date"
                  :data="{
                    inputType: 'date',
                    editable: true,
                    withSpan: false,
                    date: easyRepeatSettings.end_date
                  }"
                  :with-loading="false"
                  class="l__w--auto"
                  @child-value-change="e => handleDatepicker(e, 'end_date')"
                />
              </label>
            </p><br />
            <p>
              <label>
                <input
                  v-model="easyRepeatSettings.endtype"
                  value="count"
                  type="radio"
                  placeholder="x"
                />
                {{ translations.label_easy_issue_reccuring_after }}
                <span class="editable-input__wrapper l__w--auto">
                  <input
                    v-model="easyRepeatSettings.endtype_count_x"
                    type="number"
                    min="1"
                    max="12"
                    class="l__w--auto"
                  />
                </span>
                {{ translations.label_easy_issue_easy_reccuring_after_recurs }}
              </label>
            </p><br />
            <p>
              <label>
                <input
                  v-model="easyRepeatSettings.endtype"
                  value="endless"
                  type="radio"
                />
                {{ translations.prompt_easy_repeat_simple_repeat }}
              </label>
            </p>
            <label class="vue-modal__attribute-label">
              {{ translations.label_easy_issue_easy_repeating_endtype }}
            </label>
          </div>
          <div class="vue-modal__attribute vue-modal__attribute--rep-4">
            <p>
              <input
                v-model="easyRepeatSettings.repeat_hour"
                value="date"
                type="radio"
              />
              <InlineInput
                id="end_date"
                :data="{
                  inputType: 'time',
                  editable: true,
                  withSpan: false,
                  date: easyRepeatSettings.repeat_hour
                }"
                :with-loading="false"
                class="l__w--auto"
                @child-value-change="e => handleDatepicker(e, 'repeat_hour')"
              />
              {{ translations.hint_easy_repeating_repeat_hour_field }}
            </p>
            <label class="vue-modal__attribute-label">
              {{ translations.label_easy_is_easy_repeating_time_hour }}
            </label>
          </div>
        </div>
      </template>
    </Collapsible>

    <hr />

    <Collapsible :block="bem.block" :default-opened="false">
      <template v-slot:header>
        {{ translations.label_easy_is_easy_repeating_create_now }}
      </template>
      <template v-slot:body>
        <div class="">
          <em class="help-block">
            {{ translations.text_easy_repeating_reccuring_create_now }}
          </em>
          <span class="vue-modal__attribute" style="width: 95%">
            <p>
              <label>
                <input
                  v-model="easyRepeatSettings.create_now"
                  value="all"
                  type="radio"
                />
                {{ translations.label_easy_issue_easy_repeating_create_now_all }}
              </label>
            </p>
            <p>
              <label>
                <input
                  v-model="easyRepeatSettings.create_now"
                  value="count"
                  type="radio"
                />
                {{ translations.label_easy_issue_easy_repeating_create_now }}
                <span class="editable-input__wrapper l__w--auto">
                  <input
                    v-model="easyRepeatSettings.create_now_count"
                    placeholder="x"
                    type="number"
                    style="width: 60px !important;"
                  />
                </span>
                {{ translations.label_easy_is_easy_repeating_create_now_count_hint }}
              </label>
            </p>
          </span>
        </div>
      </template>
    </Collapsible>

    <hr />

    <p>
      <label>
        <input v-model="easyRepeatSettings.big_recurring" type="checkbox" />
        {{ translations.field_big_recurring }}
      </label>
    </p>
  </div>
</template>

<script>
import Collapsible from "../generalComponents/Collapsible";
import InlineInput from "../generalComponents/InlineInput";
import CustomOrderSelect from "./CustomOrderSelect";
import WeekDaysSelect from "./WeekDaysSelect";
import YearsSelect from "./YearsSelect";
export default {
  name: "AdvancedRepeating",
  components: {
    YearsSelect,
    WeekDaysSelect,
    CustomOrderSelect,
    InlineInput,
    Collapsible
  },
  props: {
    bem: Object,
    translations: Object,
    meeting: {
      type: Object,
      default: () => {}
    },
    easyRepeatSettings: {
      required: true,
      type: Object
    }
  },
  data() {
    return {
      daysInWeek: JSON.parse(this.translations.date_day_names)
    };
  },
  computed: {
    showDailyOption() {
      return this.easyRepeatSettings.period === "daily";
    },
    showWeeklyOption() {
      return this.easyRepeatSettings.period === "weekly";
    },
    showMonthlyOption() {
      return this.easyRepeatSettings.period === "monthly";
    },
    showYearlyOption() {
      return this.easyRepeatSettings.period === "yearly";
    }
  },
  methods: {
    handleDatepicker(e, attrName) {
      this.easyRepeatSettings[attrName] = e.inputValue;
    }
  }
};
</script>
