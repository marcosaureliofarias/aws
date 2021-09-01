import gql from "graphql-tag";

const issuePriorityEnum = gql`
  {
    allEnumerations(type: "IssuePriority") {
      id
      active
      internalName
      isDefault
      name
      position
      type
      easyColorScheme
    }
  }
`;

export default issuePriorityEnum;
