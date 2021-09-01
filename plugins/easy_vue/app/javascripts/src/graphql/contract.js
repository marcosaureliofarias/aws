import gql from "graphql-tag";

const contractQuery = gql`
  query($id: ID!) {
    easyContract(id: $id) {
      account {
        easyContactPath
        firstname
        id
        lastname
        name
      }
      createdAt
      currency
      customRepository
      discount
      easyApplication {
        easyWebApplicationPath
        id
        url
      }
      easyCrmCases {
        easyCrmCasePath
        id
        name
      }
      easyInvoices {
        easyInvoicePath
        id
        number
      }
      endDate
      id
      implementationHours
      licenseKey
      product(formatted: true)
      solution(formatted: true)
      startDate
      totalPrice(formatted: true)
      updatedAt
      userCount
      userLimit
    }
  }
`;

export { contractQuery };
