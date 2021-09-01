class AcquisitionSubmit {
  constructor(form, id) {
      this.route = `${window.urlPrefix}/easy_crm_cases/${id}/acquisition.json`;
      let reqBody = {
        easy_price_book_quote: {
          start_date: moment(form.startDate).format('YYYY-MM-DD'),
          due_date: moment(form.dueDate).format('YYYY-MM-DD'),
          solution: form.solution
        }
      };
      if (form.easyWebApplication) {
        reqBody.easy_crm_case = {
          main_easy_web_application_id: form.easyWebApplication.id
        };
      }
      this.data = {
        method: "POST",
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(reqBody)
      };
  }
  async submit() {
    try {
      const req = new Request(this.route);
      await fetch(req, this.data);
      return true;
    } catch (err) {
      console.error(err);
    }
  }
}
export default AcquisitionSubmit;