<template>
  <section :id="data.anchor" :class="bem.ify(block, 'section')">
    <h2 :class="bem.ify(block, 'heading') + ' icon-repositories'">
      {{ translations.easy_git_heading_easy_git }}
    </h2>
    <div :class="bem.ify(block, `${element}-wrapper`)">
      <TableBuilder
        :head-data="rebasedHeadData"
        :body-data="rebasedBodyData"
        :options="options"
        :table-action-buttons="tableActionButtons"
        class="list"
      />
    </div>
    <PopUp
      v-if="showPopup"
      :class="bem.ify(block, `${element}-popup-wrapper`)"
      :bem="bem"
      :task="task"
      component="MergeRequestDetail"
      :extra-data="popupData"
      :translations="translations"
      :custom-styles="customPopupStyles"
      @onBlur="showPopup = false"
    />
  </section>
</template>

<script>
import TableBuilder from "../generalComponents/TableBuilder";
import PopUp from "../generalComponents/PopUp";

export default {
  name: "MergeRequests",
  components: {
    TableBuilder,
    PopUp
  },
  props: {
    task: {
      type: Object,
      default: () => {}
    },
    data: {
      type: Object,
      default: () => {}
    },
    bem: {
      type: Object,
      default: () => {}
    },
    block: {
      type: String,
      default: "vue-modal"
    }
  },
  data() {
    return {
      translations: this.$store.state.allLocales,
      options: {
        reverseBodyOrder: true,
        showRowInput: this.$props.data.showRowInput,
        rowInputType: this.$props.data.rowInputType
      },
      showPopup: false,
      canBlur: false,
      popupData: "",
      customPopupStyles: "",
      element: this.$options.name.toLowerCase()
    };
  },
  computed: {
    tableActionButtons() {
      const buttons = [
        {
          classString: "excluded",
          icon: "icon icon-view-modal",
          title: this.translations.easy_git_title_detail_easy_git_repository,
          cb: payload => this.handlePopup(payload)
        }
      ];
      return buttons;
    },
    mergeList() {
      return this.$props.data.list;
    },
    rebasedBodyData() {
      let dataArray = [];
      if (!this.data.list) return dataArray;
      dataArray = this.data.list.map((item, i) => {
        let requests = {};
        let tests = {};
        item.codeRequests.forEach((request) => {
          this.addBadge(requests, request.statusIcon);
          this.addBadge(tests, request.easyGitTest.statusIcon);
        });
        const subject = `<a class="one-line-row" title="${item.repository.name}" href="/easy_git_commits?
  easy_git_repository_id=${item.repository.id}&issues.id=${this.task.id}&set_filter=1"
  target="_blank">${item.repository.name}</a>`;
        const lastRequest = item.codeRequests[0]?.name || "";
        const commit = `<span class="one-line-row" title="${item.repository.name}">${lastRequest}</span>`;
        const requestsHTML = this.buildBadgeHTML(requests, "requests");
        const testsHTML = this.buildBadgeHTML(tests, "tests");
        const row = {
          id: item.repository.id,
          element: item,
          index: i,
          body: [
            { label: item.resultIcon},
            { label: subject },
            { label: commit },
            { label: requestsHTML },
            { label: testsHTML}
          ],
          buttonsPermissions: []
        };
        return row;
      });
      return dataArray;
    },
    rebasedHeadData() {
      const columns = [
        { label: "" },
        { label: this.translations.easy_git_heading_index_easy_git_repository },
        { label: this.translations.easy_git_heading_index_easy_git_last_commit },
        { label: this.translations.easy_git_heading_index_easy_git_requests },
        { label: this.translations.easy_git_heading_index_easy_git_test}
      ];
      return [ columns ];
    }
  },
  methods: {
    addBadge(obj, index) {
      obj[index] = obj[index] ? obj[index]++ : 1;
    },
    buildBadgeHTML(badges, type){
      const states = ['badge-positive', 'badge-important', 'badge-negative'];
      const result = states.reduce((html, state) => {
        if (badges[state]) {
          const titleTranslation = this.translations[`easy_git_title_${type}_easy_git_${state}`];
          const title = `${badges[state]} ${titleTranslation}`;
          return `${html} <a target='_blank' title="${title}" class='badge ${state} count-badge'>${badges[state]}</a>`;
        }
        return html;
      }, "");
      return result;
    },
    handlePopup(payload) {
      this.setPopupStyles({
        position: "fixed !important",
        "min-height": `400px`,
        "max-width": "600px",
        left: "50% !important",
        top: "50% !important",
        transform: "translate(-50%, -50%) !important",
        display: "flex"
      });
      this.popupData = payload;
      this.showPopup = true;
    },
    setPopupStyles(styles) {
      this.customPopupStyles = styles;
    }
  }
};
</script>

