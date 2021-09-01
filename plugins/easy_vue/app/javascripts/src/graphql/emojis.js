import gql from "graphql-tag";

const allAvailableEmojisQuery = gql`
  query {
    allAvailableEmojis
  }
`;

const createEmoji = gql`
  mutation($entityId: ID!, $emojiId: ID!) {
    easyEmojiCreate(entityId: $entityId, emojiId: $emojiId) {
      entityEmoji {
        id
        emoji
      }
      errors
    }
  }
`;

const removeEmoji = gql`
  mutation($entityId: ID!, $emojiId: ID!) {
    easyEmojiDelete(entityId: $entityId, emojiId: $emojiId) {
      errors
    }
  }
`;

const emojisQuery = `easyEmojis {
    emoji
    emojiId
    author {
      name
      id
      avatarUrl
    }
  }`;

export { allAvailableEmojisQuery, createEmoji, removeEmoji, emojisQuery };
