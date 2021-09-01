import gql from "graphql-tag";

// Add settings you want to include into app
const keys = `[
  "text_formatting",
  "date_format",
  "time_format",
]`;

const activitySettings = gql(`
  query {
      allSettings(keys: ${keys}){
        key
        value
      }
    }
  `);

export default activitySettings;
