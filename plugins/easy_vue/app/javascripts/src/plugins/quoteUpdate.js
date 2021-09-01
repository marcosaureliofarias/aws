class QuoteUpdate {
    constructor(form, id) {
      this.route = `${window.urlPrefix}/easy_price_book_quotes/${id}.json`;
      let reqBody = {
        easy_price_book_quote: form,
      };
      if (reqBody.easy_price_book_quote.solutions === 'server') {
        reqBody.easy_price_book_quote.subscription_type = 'none';
      }
      this.data = {
        method: "PUT",
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(reqBody)
      };
    }
    async update() {
      try {
        const req = new Request(this.route);
        await fetch(req, this.data);
        return true;
      } catch (err) {
        console.error(err);
      }
    }
  }
  export default QuoteUpdate;