import gql from "graphql-tag";

const onPremiseApplicationQuery = gql`
  query($id: ID!) {
    onPremiseApplication(id: $id) {
      appServer
      attachments {
        id
      }
      createdAt
      description(formatted: true)
      editable
      hostname
      id
      ipAddress
      issuesCount
      lastUpdatedAt
      osType
      osVersion
      projectsCount
      redmineRootPath
      restartScript
      status
      updatedAt
      usersCount
      usersLimit
      version
      webServer
      journals(all: false) {
        details {
          asString
          id
        }
        deletable
        editable
        createdOn
        id
        notes(formatted: true)
        user {
          id
          name
          avatarUrl
        }
      }
    }
  }
`;

const onPremiseApplicationJournals = gql`
  query($id: ID!, $all: Boolean) {
    onPremiseApplication(id: $id) {
      journals(all: $all) {
        details {
          asString
          id
        }
        deletable
        editable
        createdOn
        id
        notes(formatted: true)
        user {
          id
          name
          avatarUrl
        }
      }
    }
  }
`;

export { onPremiseApplicationQuery, onPremiseApplicationJournals };
