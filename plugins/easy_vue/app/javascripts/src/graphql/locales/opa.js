import gql from "graphql-tag";
import { globalLocales } from "./global";

const opaModalLocales = gql`
  {
    allLocales(
      keys: [
        "activerecord.attributes.easy_on_premise_application.app_server"
        "activerecord.attributes.easy_on_premise_application.created_at"
        "activerecord.attributes.easy_on_premise_application.description"
        "activerecord.attributes.easy_on_premise_application.hostname"
        "activerecord.attributes.easy_on_premise_application.ip_address"
        "activerecord.attributes.easy_on_premise_application.issues_count"
        "activerecord.attributes.easy_on_premise_application.last_updated_at"
        "activerecord.attributes.easy_on_premise_application.os_type"
        "activerecord.attributes.easy_on_premise_application.os_version"
        "activerecord.attributes.easy_on_premise_application.projects_count"
        "activerecord.attributes.easy_on_premise_application.redmine_root_path"
        "activerecord.attributes.easy_on_premise_application.restart_script"
        "activerecord.attributes.easy_on_premise_application.status"
        "activerecord.attributes.easy_on_premise_application.updated_at"
        "activerecord.attributes.easy_on_premise_application.users_count"
        "activerecord.attributes.easy_on_premise_application.users_limit"
        "activerecord.attributes.easy_on_premise_application.version"
        "activerecord.attributes.easy_on_premise_application.web_server"
        ${globalLocales}
      ]
    ) {
      key
      translation
    }
  }
`;

export default opaModalLocales;
