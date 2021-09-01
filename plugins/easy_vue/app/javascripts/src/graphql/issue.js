import gql from "graphql-tag";

export default function issuePrimaryQueryBuilder(sprintOn, checklistOn, durationOn)
{
  const projectPermissions = checklistOn ? "addableChecklists addableChecklistItems visibleChecklists" : "";
  function addConditionalFields(){
    let conditionalFields = "";
    const sprint = `
      easySprintVisible
      easySprint{
          capacity
          closed
          name
        }
        easyStoryPoints`;
    const duration = `
      duration
      availableDurationUnits {
        key
        value
      }`;
    conditionalFields += sprintOn ? sprint : "";
    conditionalFields += durationOn ? duration : "";
    return conditionalFields;
  }

  const x = `
  query($id: ID!) {
    issue(id: $id) {
      id
      category
      subject
      safeAttributeNames
      description(formatted: true)
      author {
        id
        name
        avatarUrl
        attendanceStatus
        attendanceStatusCss
      }
      tracker {
        disabledFields
        enabledFields
        id
        name
      }
      editable
      deletable
      addIssues
      moveIssues
      copyIssues
      priority {
        active
        id
        easyColorScheme
        name
        type
      }
      status {
        id
        isClosed
        name
      }
      assignedTo {
        id
        name
        avatarUrl
        attendanceStatus
        attendanceStatusCss
      }
      createdOn
      dueDate
      estimatedHours
      isFavorite
      isPrivate
      project {
        id
        name
        activitiesPerRole {
          id
          name
          internalName
          isDefault
          type
        }
        enabledModuleNames
        enabledFeatures
        ${projectPermissions}
      }
      privateNotesEnabled
      setIsPrivate
      spentHours
      startDate
      subject
      tracker {
        id
        name
      }
      updatedOn
      doneRatio
      tags {
        id
        name
      }
      watchers {
        name
        id
        avatarUrl
      }
      version {
        id
        name
        status
      }
      ${addConditionalFields(sprintOn)}
    }
  }
`;
  const query = gql(x);
  return query;
}
