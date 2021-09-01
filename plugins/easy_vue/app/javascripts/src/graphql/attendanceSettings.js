import gql from "graphql-tag";

// Add settings you want to include into app
const keys = `[
  "text_formatting",
  "date_format",
  "time_format",
]`;

const attendanceSettings = gql(`
  query {
      allSettings(keys: ${keys}){
        key
        value
      }
    }
  `);

export default attendanceSettings;