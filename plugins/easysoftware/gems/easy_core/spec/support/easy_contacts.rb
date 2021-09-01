RSpec.shared_context "easy contacts" do
  let(:contact_type) { FactoryBot.create(:easy_contact_type, :default) }
  %w(street city postal_code country email).each do |i|
    let("cf_#{i}") do
      EasyContactCustomField.find_by(internal_name: "easy_contacts_#{i}") ||
          FactoryBot.create(:easy_contact_custom_field, internal_name: "easy_contacts_#{i}", contact_types: [contact_type])
    end
  end
  let(:easy_contact_with_address) do
    FactoryBot.create(:easy_contact, easy_contact_type: contact_type, custom_field_values: {
        cf_street.id => "Vlhka 69",
        cf_city.id => "Brno",
        cf_country.id => "Morava"
    })
  end

end
