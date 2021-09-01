import gql from "graphql-tag";

const allProjectsQuery = gql`
  query($filter: EasyProjectQueryFilter) {
    allProjects(filter: $filter) {
      id
      name
      description
    }
  }
`;

export default allProjectsQuery;
