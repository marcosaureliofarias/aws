<template>
  <ul :class="bem.ify(block, 'overview')">
    <li v-if="task.tags.length" :class="bem.ify(block, 'overview-item')">
      <List
        :items="activeTags"
        :popup-type="'tags'"
        :bem="bem"
        :options="{ itemClass: 'tag' }"
        @list-more="$emit('list-more', $event)"
      />
    </li>
    <li
      v-if="showByTracker('done_ratio')"
      :class="`${bem.ify(block, 'overview-item')} ${doneRatioPermClass}`"
      @click="toggleProgressInput($event)"
    >
      <label
        :class="
          bem.ify(block, `attribute-label`) +
            ' ' +
            bem.ify(block, `overview-label`)
        "
      >
        {{ $store.state.allLocales.label_progress }}
      </label>
      <ProgressBar
        :type="'doneRatio'"
        :ratio="task.doneRatio"
        :title="$store.state.allLocales.button_edit"
      />
      <InlineInput
        v-if="showByTracker('done_ratio') && showProgressInput && workflowDoneRatio"
        :id="task.id"
        ref="progress-input"
        :bem="bem"
        :searchable="progress.searchable"
        :options-array="progress.optionsArray"
        :value="progress.value"
        :data="progress.data"
        class="v-select--progress"
        @child-value-change="
          saveValue($event, 'done_ratio', 'doneRatio', getValue)
        "
        @search:blur="showProgressInput = false"
      />
    </li>
    <li
      v-if="showTimeRatio && isModuleEnabled('time_tracking')"
      :class="bem.ify(block, 'overview-item')"
    >
      <label
        :class="
          bem.ify(block, `attribute-label`) +
            ' ' +
            bem.ify(block, `overview-label`)
        "
      >
        {{ $store.state.allLocales.field_spent_estimated_timeentries }}
      </label>
      <ProgressBar
        :type="'timeRatio'"
        :ratio="getTimeRatio"
        @hide-time-ratio="showTimeRatio = false"
      />
    </li>
    <li :class="bem.ify(block, 'overview-item')">
      <a
        v-if="isAssignee()"
        title="By clicking show profile."
        target="_blank"
        :href="activeAssignee.avatarLink"
        :class="bem.ify(block, 'overview-avatar') + ' avatar__wrapper'"
      >
        <img
          alt=""
          title=""
          class="gravatar"
          :srcset="activeAssignee.avatarUrl + ' 2x'"
          :src="activeAssignee.avatarUrl"
        />
      </a>
      <List
        v-if="showCoworkers"
        :items="$store.state.issue.watchers"
        :popup-type="'coworkers'"
        :options="{
          listClass: bem.ify(block, 'coworkers-overview-list'),
          itemClass: bem.ify(block, 'coworkers-overview-list-item')
        }"
        :bem="bem"
        @list-more="$emit('list-more', $event)"
      >
        <template v-slot:item="{ index }">
          <a
            title="By clicking show profile."
            target="_blank"
            :href="`${urlPrefix}/users/${$store.state.issue.watchers[index].id}/profile`"
            :class="
              bem.ify(block, 'overview-avatar') +
                ' avatar__wrapper ' +
                bem.ify(block, 'overview-avatar--coworker')
            "
          >
            <img
              alt="#"
              class="gravatar"
              :srcset="$store.state.issue.watchers[index].avatarUrl + ' 2x'"
              :src="$store.state.issue.watchers[index].avatarUrl"
            />
          </a>
        </template>
      </List>
    </li>
  </ul>
</template>

<script>
import ProgressBar from "./../generalComponents/ProgressBar";
import List from "./List";
import InlineInput from "../generalComponents/InlineInput";
import userQuery from "../../graphql/user";
import { IssueDoneRatioEnum } from "../../enums/settings";

export default {
  name: "Overview",
  components: {
    InlineInput,
    List,
    ProgressBar
  },
  props: {
    bem: Object,
    task: Object,
    spentHours: [Number, String],
    estimatedHours: [Number, String]
  },
  data() {
    return {
      block: this.$props.bem.block,
      element: this.$props.bem.element,
      modifier: this.$options.name.toLowerCase(),
      showTimeRatio: true,
      showProgressInput: false,
      urlPrefix: window.urlPrefix
    };
  },
  computed: {
    progress() {
      return {
        data: {
          withSpan: false,
          inputType: "autocomplete",
          classes: { edit: ["u-editing"], show: ["u-showing"] },
          filterable: true,
          editable: this.task.editable
        },
        searchable: false,
        value: this.$store.state.issue.doneRatio
          ? this.$store.state.issue.doneRatio
          : "",
        optionsArray: this.createDoneRatioOptions()
      };
    },
    editDoneRatio() {
      const doneRatioEditable = IssueDoneRatioEnum.USE_ISSUE_FIELD === this.$store.state.allSettings.issue_done_ratio;
      return this.workflowDoneRatio && doneRatioEditable;
    },
    showCoworkers() {
      // show coworkers only if server sent them
      const watchers = this.$store.state.issue.watchers;
      return watchers && watchers.length;
    },
    activeUrl: {
      get() {
        let url;
        if (
          this.$props.task.assignedTo &&
          this.$props.task.assignedTo.avatarUrl
        ) {
          url = this.$props.task.assignedTo.avatarUrl;
        } else if (
          this.$store.state.assignee &&
          this.$store.state.assignee.avatarUrl
        ) {
          url = this.$store.state.assignee.avatarUrl;
        } else {
          url = null;
        }
        return url;
      }
    },
    activeLink: {
      get() {
        let linkId;
        if (this.$props.task.assignedTo && this.$props.task.assignedTo.id) {
          linkId = this.$props.task.assignedTo.id;
        } else if (
          this.$store.state.assignee &&
          this.$store.state.assignee.id
        ) {
          linkId = this.$store.state.assignee.id;
        } else {
          linkId = null;
        }
        let link = `${this.urlPrefix}/users/${linkId}/profile`;
        return link;
      }
    },
    activeAssignee: {
      get() {
        const assignee = {
          avatarUrl: this.activeUrl,
          avatarLink: this.activeLink
        };
        return assignee;
      }
    },
    getTimeRatio() {
      const { spentHours, estimatedHours } = this.$props;
      const ratio = this.getTotalRatio(spentHours, estimatedHours);
      return ratio;
    },
    activeTags() {
      return this.$props.task.tags;
    },
    workflowDoneRatio() {
      return this.workFlowChangable("done_ratio");
    },
    doneRatioPermClass() {
      return this.editDoneRatio ? "editable" : "no-hover";
    },
    assignedTo() {
      return this.$props.task.assignedTo;
    }
  },
  watch: {
    assignedTo: function (val, oldVal) {
      if (val.id === oldVal.id) return;
      if(!val.avatarUrl){
        this.fetchUser(val.id);
      }
    }
  },
  methods: {
    async fetchUser(id) {
      const payload = {
        name: "user",
        level: "issue",
        storeAs: "assignedTo",
        apolloQuery: {
          query: userQuery,
          variables: { id: id }
        }
      };
      await this.$store.dispatch("fetchStateValue", payload);
    },
    toggleProgressInput() {
      if (!this.editDoneRatio) return;
      this.showProgressInput = true;
      this.$nextTick(() => {
        const el = this.$refs["progress-input"].$el;
        el.querySelector("input").focus();
      });
    },
    createDoneRatioOptions() {
      const optionsArray = [];
      for (let i = 0; i <= 10; i++) {
        const option = {
          value: i * 10,
          name: `${i * 10}%`
        };
        optionsArray.push(option);
      }
      return optionsArray;
    },
    isAssignee() {
      let hasAssignee;
      if (
        this.$props.task.assignedTo &&
        this.$props.task.assignedTo.avatarUrl
      ) {
        hasAssignee = this.$props.task.assignedTo.avatarUrl;
      } else if (
        this.$store.state.assignee &&
        this.$store.state.assignee.avatarUrl
      ) {
        hasAssignee = this.$store.state.assignee.avatarUrl;
      }

      if (hasAssignee) return true;
      else return false;
    }
  }
};
</script>

<style lang="scss" scoped></style>
