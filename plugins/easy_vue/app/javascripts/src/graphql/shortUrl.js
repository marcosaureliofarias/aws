import gql from "graphql-tag";

const createShortUrl = gql`
  mutation($entityId: ID!, $entityType: String!, $attributes: EasyShortUrlAttr!) {
    easyShortUrlCreate(entityId: $entityId, entityType: $entityType, attributes: $attributes){
      easyShortUrl {
        shortUrl
        shortcut,
        validTo,
        allowExternal
      }
      errors
    }
  }
`;

export default createShortUrl;