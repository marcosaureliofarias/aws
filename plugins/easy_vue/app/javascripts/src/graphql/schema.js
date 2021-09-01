import gql from "graphql-tag";

const issueSchema = gql`
  query IntrospectionQuery {
    __type(name: "Issue") {
      fields{
        name
      }
    }
  }
`
;

export default issueSchema;