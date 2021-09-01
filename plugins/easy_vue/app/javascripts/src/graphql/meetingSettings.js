import gql from "graphql-tag";

// Add settings you want to include into app
const keys = `[
  "date_format",
  "time_format",
  "text_formatting"
]`;

const meetingSettings = gql(`
  query {
      allSettings(keys: ${keys}){
        key
        value
      }
    }
  `);

export default meetingSettings;
