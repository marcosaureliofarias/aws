<template>
  <div
    ref="div"
    :class="bem.ify(block, element)"
    tabindex="0"
    @blur="$emit('on-blur')"
  >
    <div :class="bem.ify(block, `${element}-head`)">
      <h4 :class="bem.ify(block, `${element}-heading`)">
        {{ data.row.element.repository.name }}
        <a target="_blank" class="icon icon-external" :href="repositoryUrl" />
      </h4>
    </div>
    <div :class="bem.ify(block, `${element}-table-wrapper`)">
      <TableBuilder
        :head-data="rebasedHeadData"
        :body-data="rebasedBodyData"
        :options="options"
        :table-action-buttons="[]"
        class="list"
      />
    </div>
    <div class="vue-modal__button-panel">
      <span>
        <a
          :class="
            `${bem.ify(
              block,
              `${element}-button-confirm`
            )} button-mini-positive excluded`
          "
          :href="data.row.element.newExternalCodeRequestUrl"
          target="_blank"
        >
          {{ translations.easy_git_button_new_easy_git_request }}
        </a>
      </span>
      <span>
        <a
          :class="
            `${bem.ify(
              block,
              `${element}-button-confirm`
            )} button-mini-positive excluded`
          "
          :href="data.row.element.newExternalTestUrl"
          target="_blank"
        >
          {{ translations.easy_git_button_new_easy_git_test }}
        </a>
      </span>
    </div>
  </div>
</template>

<script>
import TableBuilder from "../generalComponents/TableBuilder";

export default {
  name: "MergeRequestDetail",
  components: {
    TableBuilder
  },
  props: {
    bem: {
      type: Object,
      default: () => {}
    },
    data: {
      type: Object,
      default: () => {}
    },
    translations: {
      type: Object,
      default: () => {}
    },
    task: {
      type: Object,
      default: () => {}
    },
  },
  data() {
    return {
      options: {
        reverseBodyOrder: true,
        showRowInput: this.$props.data.showRowInput,
        rowInputType: this.$props.data.rowInputType
      },
      block: this.$props.bem.block,
      element: 'merge-request-detail',
    };
  },
  computed: {
    rebasedBodyData() {
      let dataArray = [];
      if (!this.data.row.element.codeRequests) return dataArray;
      dataArray = this.data.row.element.codeRequests.map((request, i) => {
        const requestBadge = `<a target='_blank' class='badge ${request.statusIcon}' href='${request.gitWebUrl}'>
${request.labelEasyCodeRequestShortcut} : ${request.status}</a>`;
        const testBadge = `<a target='_blank' class='badge ${request.easyGitTest.statusIcon}' 
href='${request.easyGitTest.gitWebUrl}'>CI : ${request.easyGitTest.status}</a>`;
        const row = {
          id: request.id,
          element: request,
          index: i,
          body: [
            { label: request.name },
            { label: requestBadge },
            { label: testBadge}
          ],
          buttonsPermissions: []
        };
        return row;
      });
      return dataArray;
    },
    rebasedHeadData() {
      const columns = [
        { label: this.translations.activerecord_attributes_easy_git_code_request_name },
        { label: this.translations.easy_git_heading_index_easy_git_merge_status },
        { label: this.translations.easy_git_heading_index_easy_git_test_status}
      ];
      return [ columns ];
    },
    repositoryUrl() {
      return `/easy_git_commits?easy_git_repository_id=${this.data.row.element.repository.id}
&issues.id=${this.task.id}&set_filter=1`;
    }
  }
};
</script>
