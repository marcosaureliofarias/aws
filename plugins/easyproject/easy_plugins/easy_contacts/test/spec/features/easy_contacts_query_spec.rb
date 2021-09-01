require 'easy_extensions/spec_helper'

feature 'Easy Contact query', logged: :admin do

  context 'contacts index' do
    let(:person) { FactoryGirl.create(:personal_easy_contact_type, is_default: true) }
    let(:easy_contact_group) { FactoryGirl.create(:easy_contact_group, group_name: 'public', author_id: User.current, is_public: true) }
    let!(:john) { FactoryGirl.create(:easy_contact, firstname: 'John', lastname: 'Smith', type_id: person.id) }

    it 'grouped by contact_groups', js: true do
      visit easy_contacts_path(set_filter: '1', group_by: 'contact_groups')
      page.find('span.expander').click
      expect(page).to have_css("#entity-#{john.id}")
    end

    it 'grouped and sorted by contact_groups', js: true do
      visit easy_contacts_path(set_filter: '1', group_by: 'contact_groups', sort: 'contact_groups')
      page.find('span.expander').click
      expect(page).to have_css("#entity-#{john.id}")
    end

    it 'with contact_groups column', js: true do
      visit easy_contacts_path(set_filter: '1', column_names: ['contact_groups'])
      expect(page).to have_css("#entity-#{john.id}")
    end
  end

end
