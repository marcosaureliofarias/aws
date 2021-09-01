RSpec.describe 'easy_contacts/_sidebar' do
  let(:personal_contact_type) { FactoryBot.create(:easy_contact_type, :personal)}
  let(:easy_contact) { FactoryBot.create(:easy_contact, :personal, { easy_contact_type: personal_contact_type }) }

  context 'computed custom fields', skip: !Redmine::Plugin.installed?(:easy_contacts) do
    let!(:custom_field) { FactoryBot.create(:easy_contact_custom_field, field_format: 'easy_computed_from_query', contact_types: [personal_contact_type]) }

    it 'recalculate button' do
      expect(easy_contact.available_custom_fields).to include custom_field
      assign(:easy_contact, easy_contact)
      render partial: 'easy_contacts/sidebar', locals: {entity: easy_contact}
      expect(rendered).to match I18n.t(:button_recalculate_computed_from_query)
    end

  end
end
