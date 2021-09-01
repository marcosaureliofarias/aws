class LogTime {

  constructor(params) {
    const { timeEntryToUpdate, timeEntryId, method, route } = params;
    this.updateRoute = `${route}/${timeEntryId}.json`;
    this.createRoute = `${route}.json`;
    this.data = {
      body: JSON.stringify(timeEntryToUpdate),
      method,
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json"
      }
    };
  }

  async update() {
    try {
      const req = new Request(this.updateRoute);
      const response = await fetch(req, this.data);
      const results = await response.json();
      return results;
    } catch (err) {
      return err;
    }
  }

  async create() {
    try {
      const req = new Request(this.createRoute);
      const response = await fetch(req, this.data);
      const { errors } = await response.json();
      return { errors };
    } catch (err) {
      return err;
    }
  }
}

export default LogTime;