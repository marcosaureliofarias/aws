class QuoteSubmit {
  constructor(form) {
    this.route = `${window.urlPrefix}/easy_price_book_quotes.json`;
    let reqBody = {
      easy_price_book_quote: form,
    };
    if (reqBody.easy_price_book_quote.solutions === 'server') {
      reqBody.easy_price_book_quote.subscription_type = 'none';
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
      const response = await fetch(req, this.data);
      const json = await response.json();
      return json;
    } catch (err) {
      console.error(err);
    }
  }
}
export default QuoteSubmit;