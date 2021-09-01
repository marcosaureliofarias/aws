import gql from "graphql-tag";

const checkListsQuery = gql`
  query($id: ID!) {
    issue(id: $id) {
      id
      checklists {
        id
        name
        easyChecklistItems {
          id
          subject
          done
          canEnable
          canDisable
          editable
          deletable
        }
        deletable
        editable
      }
    }
  }
`;

export default checkListsQuery;
