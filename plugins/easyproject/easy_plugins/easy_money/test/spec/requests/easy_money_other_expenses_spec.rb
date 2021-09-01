require "easy_extensions/spec_helper"

RSpec.describe EasyMoneyOtherExpensesController do
  context "as admin", logged: :admin do
    describe "#show" do
      subject { FactoryBot.create(:easy_money_other_expense, easy_external_id: "5-5") }

      it "json" do
        get "/easy_money_other_expenses/#{subject.id}.json", params: { id: subject }
        expect(response).to have_http_status :success
        expect(response.body).to include "easy_external_id"
      end

    end
  end
end