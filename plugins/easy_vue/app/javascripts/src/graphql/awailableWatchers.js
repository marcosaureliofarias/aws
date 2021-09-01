
export default function watchersQuery(id, term) {
  const query = `
    {
      issue(id: ${id}) {
        id
        newAvailableWatchers(q: "${term || ''}" ) {
          id
          name
          avatarUrl
        }
      }
    }
  `;
  return query;
};