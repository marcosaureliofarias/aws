import gql from "graphql-tag";

const attendanceOverviewQuery = gql`
  query($userIds: [ID!]) {
    easyAttendancesApproval(userIds: $userIds) {
      easyAttendances {
        approvalStatus {
          key
          value
        }
        arrival
        departure
        id
        easyAttendanceActivity {
          id
          name
        }
        user {
          avatarUrl
          id
          name
        }
      }
      isExceeded
    }
  }
`;

export { attendanceOverviewQuery };
