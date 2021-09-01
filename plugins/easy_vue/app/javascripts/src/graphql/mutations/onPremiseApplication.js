import gql from "graphql-tag";

const onPremiseApplicationPatch = gql`
  mutation($entityId: ID!, $attributes: EasyOnPremiseApplicationAttr!) {
    onPremiseApplicationUpdate(id: $entityId, attributes: $attributes) {
      easyOnPremiseApplication {
        status
      }
      errors
    }
  }
`;

const createUpdateJournal = gql`
  mutation($id: ID, $entityId: ID, $entityType: String, $notes: String!) {
    journalChange(
      id: $id
      entityId: $entityId
      entityType: $entityType
      notes: $notes
    ) {
      errors
      journal {
        createdOn
        deletable
        details {
          asString
          id
          oldValue
          propKey
          property
          value
        }
        editable
        id
        notes(formatted: true)
        user {
          avatarUrl
          id
          name
        }
      }
    }
  }
`;

export { onPremiseApplicationPatch, createUpdateJournal };
