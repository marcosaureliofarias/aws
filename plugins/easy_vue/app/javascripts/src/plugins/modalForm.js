class ModalFormFetcher {
  constructor(endpoint) {
    this.route = `${window.urlPrefix}${endpoint}`;
    this.data = {
      method: "GET",
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      }
    };
  }
  async fetch() {
    try {
      const req = new Request(this.route);
      const response = await fetch(req, this.data);
      const json = await response.json();
      return json;
    } catch (err) {
      return err;
    }
  }
}
export default ModalFormFetcher;
  