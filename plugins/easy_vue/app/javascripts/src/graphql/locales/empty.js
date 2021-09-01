import gql from "graphql-tag";
import { globalLocales } from "./global";

const emptyModalLocales = gql`
  {
    allLocales(
      keys: [
        ${globalLocales}
      ]
    ) {
      key
      translation
    }
  }
`;

export default emptyModalLocales;
