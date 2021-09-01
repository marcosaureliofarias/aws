import gql from "graphql-tag";

const markAsRead = gql`
  mutation($entityId: ID!, $entityType: String!) {
    markAsRead(entityId: $entityId, entityType: $entityType){
      errors
    }
  }
`;

export default markAsRead;
