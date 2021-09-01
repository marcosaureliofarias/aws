RSpec.describe "Easy Core factory" do

  def factories(names)
    names.collect { |name| FactoryBot::Internal.factory_by_name(name) }
  end

  context "EasyUserType" do
    it { FactoryBot.lint factories(%i[easy_user_type]) }
  end

  context "easy_crm", skip: !Redmine::Plugin.installed?(:easy_crm) do
    it { FactoryBot.lint factories(%i[easy_crm_case_status easy_crm_case_item easy_crm_case_custom_field easy_crm_case]) }
  end

  context "easy_invoicing", skip: !Redmine::Plugin.installed?(:easy_invoicing) do
    it { FactoryBot.lint factories(%i[invoice_custom_field easy_invoice_line_item easy_invoice_payment_method easy_invoice_sequence easy_invoice]) }
  end

  context "easy_contacts", skip: !Redmine::Plugin.installed?(:easy_contacts) do
    it { FactoryBot.lint factories(%i[easy_contact_custom_field easy_contact_type]) }

    describe "contacts" do
      include_context "easy contacts"

      it "easy contact random address" do
        expect(easy_contact_with_address.cf_street_value).to include "Vlhka"
      end

    end

    describe "contacts 2" do
      include_context "easy contacts"

      it "easy contact random address" do
        expect(easy_contact_with_address.cf_city_value).to include "Brno"
      end
    end

  end

  context "easy_calendar", skip: !Redmine::Plugin.installed?(:easy_calendar) do
    around do |example|
      ActiveJob::Base.queue_adapter = :inline
      example.run
      ActiveJob::Base.queue_adapter = :test
    end
    it "big recurring" do
      expect { FactoryBot.create :big_repeating_meeting }.to change(EasyMeeting, :count).by_at_least 100
    end
  end

end
