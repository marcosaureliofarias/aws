<template>
  <section id="detail" :class="bem.ify(bem.block, 'section')">
    <ul :class="bem.ify(bem.block, 'attributes')">
      <Attribute
        :id="id"
        :bem="bem"
        :data="status"
        @child-value-change="saveValue($event, 'status')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="appServer"
        @child-value-change="saveValue($event, 'appServer')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="version"
        @child-value-change="saveValue($event, 'version')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="webServer"
        @child-value-change="saveValue($event, 'webServer')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="restartScript"
        @child-value-change="saveValue($event, 'restartScript')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="redmineRootPath"
        @child-value-change="saveValue($event, 'redmineRootPath')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="ipAddress"
        @child-value-change="saveValue($event, 'ipAddress')"
      />
      <Attribute :id="id" :bem="bem" :data="createdAt" />
      <Attribute :id="id" :bem="bem" :data="lastUpdatedAt" />
      <Attribute
        :id="id"
        :bem="bem"
        :data="osType"
        @child-value-change="saveValue($event, 'osType')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="osVersion"
        @child-value-change="saveValue($event, 'osVersion')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="usersLimit"
        @child-value-change="saveValue($event, 'usersLimit')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="usersCount"
        @child-value-change="saveValue($event, 'usersCount')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="projectsCount"
        @child-value-change="saveValue($event, 'projectsCount')"
      />
      <Attribute
        :id="id"
        :bem="bem"
        :data="issuesCount"
        @child-value-change="saveValue($event, 'projectsCount')"
      />
    </ul>
  </section>
</template>

<script>
import Attribute from "../generalComponents/Attribute";
import { onPremiseApplicationPatch } from "../../graphql/mutations/onPremiseApplication.js";
export default {
  name: "Detail",
  components: { Attribute },
  props: {
    id: [Number, String],
    onPremiseApplication: Object,
    bem: Object,
    translations: Object
  },
  data() {
    return {
      status: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_status,
        value: this.onPremiseApplication.status || "",
        inputType: "text",
        optionsArray: false,
        placeholder: "---",
        withSpan: false,
        editable: this.onPremiseApplication.editable
      },
      ipAddress: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_ip_address,
        value: this.onPremiseApplication.ipAddress || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: false,
        editable: this.onPremiseApplication.editable
      },
      createdAt: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_created_at,
        value: this.dateFormat(this.onPremiseApplication.lastUpdatedAt) || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      lastUpdatedAt: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_last_updated_at,
        value: this.dateFormat(this.onPremiseApplication.createdAt) || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: false
      },
      appServer: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_app_server,
        value: this.onPremiseApplication.appServer || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      restartScript: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_restart_script,
        value: this.onPremiseApplication.restartScript || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      osType: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_os_type,
        value: this.onPremiseApplication.osType || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      osVersion: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_os_version,
        value: this.onPremiseApplication.osVersion || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      projectsCount: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_projects_count,
        value: this.onPremiseApplication.projectsCount || "",
        inputType: "int",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      issuesCount: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_issues_count,
        value: this.onPremiseApplication.issuesCount || "",
        inputType: "int",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      redmineRootPath: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_redmine_root_path,
        value: this.onPremiseApplication.redmineRootPath || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      version: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_version,
        value: this.onPremiseApplication.version || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      webServer: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_web_server,
        value: this.onPremiseApplication.webServer || "",
        inputType: "text",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      usersLimit: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_users_limit,
        value: this.onPremiseApplication.usersLimit || "",
        inputType: "int",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      },
      usersCount: {
        labelName: this.translations
          .activerecord_attributes_easy_on_premise_application_users_count,
        value: this.onPremiseApplication.usersCount || "",
        inputType: "int",
        optionsArray: false,
        filterable: false,
        placeholder: "---",
        withSpan: true,
        editable: this.onPremiseApplication.editable
      }
    };
  },
  methods: {
    async saveValue(event, storeName, options = {}) {
      const inputValue = options.parseInt
        ? parseInt(event.inputValue)
        : event.inputValue;
      const payload = {
        mutationName: "onPremiseApplicationUpdate",
        apolloMutation: {
          mutation: onPremiseApplicationPatch,
          variables: {
            entityId: this.id,
            attributes: { [storeName]: inputValue }
          }
        },
        pathToGet: [
          "onPremiseApplicationUpdate",
          "easyOnPremiseApplication",
          storeName
        ],
        pathToSet: ["onPremiseApplication", storeName],
        processFunc: event.showFlashMessage
      };
      await this.$store.dispatch("mutateValue", payload);
    }
  }
};
</script>

<style scoped></style>
