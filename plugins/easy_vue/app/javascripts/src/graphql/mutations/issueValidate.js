import gql from "graphql-tag";
export default function issueValidate(sprintOn, checklistOn, durationOn) {
  const projectPermissions = checklistOn ? "addableChecklists addableChecklistItems visibleChecklists" : "";
  function addConditionalFields(){
    let conditionalFields = "";
    const sprint = `
      easySprint {
        capacity
        closed
        name
      }
      easySprintVisible
      easyStoryPoints
    `;
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

const issueValidate = `
  mutation($id: ID, $attributes: JSON!) {
    issueValidator(attributes: $attributes, id: $id){
      issue {
        id
        category
        subject
        deletable
        safeAttributeNames
        description(formatted: true)
        author {
          id
          name
          avatarUrl
        }
        tracker {
          disabledFields
          enabledFields
          id
          name
        }
        editable
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
          ${ projectPermissions }
        }
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
        addIssues
        moveIssues
        copyIssues
        ${ addConditionalFields(sprintOn) }
      }
      errors {
        attribute,
          fullMessages
      }
    }
  }
  `;
  const mutation = gql(issueValidate);
  return mutation;
};
