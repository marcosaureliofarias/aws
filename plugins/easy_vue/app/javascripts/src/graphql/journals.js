import gql from "graphql-tag";
import { emojisQuery } from "./emojis";

export default function fetchJournals(type, emojiOn) {
  let journalsQuery;
  const addEmojiQuery = emojiOn ? emojisQuery : "";
  if (type === "issue") {
    journalsQuery = `
      query($id: ID!, $all: Boolean) {
        issue(id: $id) {
          id
          journals(all: $all) {
            editable
            deletable
            details {
              asString
              id
            }
            createdOn
            id
            notes(formatted: true)
            ${addEmojiQuery}
            privateNotes
            user {
              id
              name
              avatarUrl
            }
          }
        }
      }
    `;
  } else {
    journalsQuery = `
      query($id: ID!, $all: Boolean) {
        project(id: $id) {
          id
          journals(all: $all) {
            editable
            deletable
            details {
              asString
              id
            }
            createdOn
            id
            notes(formatted: true)
            privateNotes
            user {
              id
              name
              avatarUrl
            }
          }
        }
      }
    `;
  }
  return gql(journalsQuery);
}
