import gql from "graphql-tag";

const attachmentsQuery = gql`
  query($id: ID!) {
    issue(id: $id) {
      id
      attachments {
        id
        author {
          name
          id
          avatarUrl
        }
        contentUrl
        createdOn
        filename
        filesize
        thumbnailPath
        attachmentPath
        editable
        deletable
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
          attachment{
            id
            version
            editable
            deletable
          }
          id
          version
          author {
            name
            id
            avatarUrl
          }
          contentUrl
          attachmentPath
          createdOn
          filename
          filesize
          editable
          deletable
        }
      }
    }
  }
`;

export default attachmentsQuery;
