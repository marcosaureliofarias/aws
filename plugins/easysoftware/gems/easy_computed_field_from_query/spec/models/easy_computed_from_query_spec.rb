RSpec.describe EasyRakeTaskComputedFromQuery, logged: :admin, skip: !Redmine::Plugin.installed?(:easy_crm) || !Redmine::Plugin.installed?(:easy_contacts) do
  let(:contact_type) { FactoryBot.create(:easy_contact_type) }
  let(:crm_status) { FactoryBot.create(:easy_crm_case_status) }
  describe ".recalculate_entity" do
    context "recalculate bool_cf to contact" do
      let(:bool_cf) { FactoryBot.create(:easy_crm_case_custom_field, id: 53, easy_crm_case_statuses: [crm_status], field_format: "bool", is_filter: true) }
      let!(:computed_cf) do
        FactoryBot.create(:easy_contact_custom_field, id: 145, contact_types: [contact_type], field_format: "easy_computed_from_query", settings:
          { "associated_query" => "EasyCrmCaseQuery",
            "easy_query_entity_filter" => "main_easy_contact_id",
            "easy_query_formula" => "last",
            "easy_query_column" => "cf_53",
            "easy_query_column_currency" => "CZK",
            "easy_query_filters" =>
              { "set_filter" => "1" },
            "easy_computed_from_query_format" => "bool" })
        end
      let(:easy_contact) { FactoryBot.create(:easy_contact, easy_contact_type: contact_type) }
      let!(:crm) { FactoryBot.create(:easy_crm_case, easy_crm_case_status: crm_status, main_easy_contact: easy_contact, custom_field_values: { bool_cf.id => "0" }) }

      it "should be false" do
        described_class.recalculate_entity(easy_contact)
        subject = EasyContact.find easy_contact.id
        expect(subject.custom_field_value(145)).to eq "0"
        expect(subject.custom_value_for(145).cast_value).to eq false
      end

      it "should be true" do
        crm.update custom_field_values: { bool_cf.id => "1" }
        described_class.recalculate_entity(easy_contact)
        subject = EasyContact.find easy_contact.id
        expect(subject.custom_field_value(145)).to eq "1"
        expect(subject.custom_value_for(145).cast_value).to eq true
      end
    end
  end
end