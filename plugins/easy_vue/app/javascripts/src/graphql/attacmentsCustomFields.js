import gql from "graphql-tag";

const attachmentsCFQuery = gql`
{
  attachmentsCustomValues {
    customField {
      id
      isRequired
      name
    }
    editTag(prefix: "attachments")
    value
    formattedValue
  }
}
`;

export default attachmentsCFQuery;
