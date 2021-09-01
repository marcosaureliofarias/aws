import gql from "graphql-tag";

// Add settings you want to include into app
const keys = `[
  "timelog_comment_editor_enabled",
  "text_formatting",
  "attachment_max_size",
  "date_format",
  "issue_private_note_as_default",
  "time_format",
  "enable_private_issues"
  "billable_things_default_state"
  "start_of_week"
  "issue_done_ratio"
]`;

const allSettingsQuery = gql(`
  query($id: ID!) {
      allSettings(keys: ${keys}, projectId: $id){
        key
        value
      }
    }
  `);

const allSettingsQueryWithoutProject = gql(`
  query {
      allSettings(keys: ${keys}){
        key
        value
      }
    }
  `);

export { allSettingsQueryWithoutProject, allSettingsQuery };
