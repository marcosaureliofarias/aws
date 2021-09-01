import gql from "graphql-tag";
import { emojisQuery } from "./emojis";

export default function issueAdditionalQueryBuilder(
  checklistsOn,
  spentTimeOn,
  mergeRequestsOn,
  emojiOn
) {
  const addEmojiQuery = emojiOn ? emojisQuery : "";
  function addConditionalFields(checklistsOn, spentTimeOn) {
    let conditionalFields = "";
    const checklists = `checklists{
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
  }`;
    const spentTime = `
      timeEntries {
        editable
        deletable
        spentOn
        easyIsBillable
        user {
          name
          id
          avatarUrl
        }
        comments
        hours
        id
        issue {
          id
          subject
        }
        project {
          id
          name
        }
      }
      timeEntriesCustomValues {
        customField {
          description
          easyGroup {
            name
            id
          }
          fieldFormat
          id
          internalName
          isRequired
          multiple
          name
          settings
          type
          formatStore
          defaultValue
        }
        possibleValues
        editable
        value
        formattedValue
      }
      timeEntriesCommentRequired
    `;
    const mergeRequests = `
      easyGitIssue {
        labelEasyCodeRequestPlural
        rows {
          resultIcon
          newExternalTestUrl
          newExternalCodeRequestUrl
          codeRequests {
            id
            name
            status
            labelEasyCodeRequestShortcut
            statusIcon
            gitWebUrl
            easyGitTest {
              status
              statusIcon
              gitWebUrl
            }
          }
          repository {
            id
            name
          }
        }
      }
    `;
    conditionalFields += checklistsOn ? checklists : "";
    conditionalFields += spentTimeOn ? spentTime : "";
    conditionalFields += mergeRequestsOn ? mergeRequests : "";
    return conditionalFields;
  }

  function timeEntriesDescendance(spentTimeOn) {
    const schema = `
      timeEntries {
        hours
        id
      }`;
      if (!spentTimeOn) return "";
      return schema;
  }

  const additionalIssueDataQuery = `
  query($id: ID!) {
    issue(id: $id) {
      id
      easyLevel
      manageSubtasks
      addableNotes
      manageSubtasks
      newAvailableWatchers(q: null) {
        id
        name
        avatarUrl
      }
      allIssueRelationTypes{
        key
        name
      }
      addableTimeEntries
      addableWatchers
      deletableWatchers
      journals (all: false){
        details {
          asString
          id
        }
        deletable
        editable
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
      attachments {
        id
        author {
          name
          id
          avatarUrl
        }
        deletable
        contentUrl
        createdOn
        filename
        filesize
        thumbnailPath
        attachmentPath
        editable
        webdavUrl
        version
        easyShortUrls{
          allowExternal
          entityId
          entityType
          id
          shortUrl
          shortcut
          sourceUrl
          validTo
        }
        versions {
          version
          id
          attachment{
            id
            version
            editable
            deletable
          }
          author {
            name
            id
            avatarUrl
          }
          contentUrl
          createdOn
          attachmentPath
          filename
          filesize
          editable
          deletable
        }
      }
      customValues {
        customField {
          description
          easyGroup {
            name
            id
          }
          fieldFormat
          id
          internalName
          isRequired
          multiple
          name
          settings
          type
          formatStore
          defaultValue
        }
        possibleValues
        editable
        value
        formattedValue
      }
        descendants {
          subject
          id
          easyLevel
          status {
            id
            isClosed
            name
          }
          assignedTo {
            id
            name
            avatarUrl
          }
          doneRatio
          priority {
            id
            easyColorScheme
            name
          }
          ${timeEntriesDescendance(spentTimeOn)}
        }
        ancestors {
          subject
          id
          easyLevel
          status {
            id
            isClosed
            name
          }
          assignedTo {
            id
            name
            avatarUrl
          }
          doneRatio
          priority {
            id
            easyColorScheme
            name
          }
        }
        relations{
          id
          otherIssue(issueId: $id){
            subject
            id
            easyLevel
            status {
              id
              isClosed
              name
            }
            assignedTo {
              id
              name
              avatarUrl
            }
            doneRatio
            priority {
              id
              easyColorScheme
              name
            }
          }
          relationName(issueId: $id)
    }
    ${addConditionalFields(checklistsOn, spentTimeOn)}
  }
}`;

  return gql(additionalIssueDataQuery);
}
