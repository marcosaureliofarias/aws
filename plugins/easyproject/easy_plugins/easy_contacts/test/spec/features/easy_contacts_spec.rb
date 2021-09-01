require 'easy_extensions/spec_helper'

feature 'Easy Contacts', logged: :admin, js: true, js_wait: :long do

  context 'Non-primary custom fields' do
    let(:cf1) { FactoryGirl.create(:easy_contact_custom_field, :name => 'non-primary-show-empty', :field_format => 'string', :is_primary => false, :show_empty => true) }
    let(:cf2) { FactoryGirl.create(:easy_contact_custom_field, :name => 'non-primary-hide-empty', :field_format => 'string', :is_primary => false, :show_empty => false) }

    let(:person) { p = FactoryGirl.create(:personal_easy_contact_type, is_default: true); p.custom_fields << cf1; p.save; p }
    let(:company) { c = FactoryGirl.create(:corporate_easy_contact_type, is_default: false); c.custom_fields << cf2; c.save; c }

    it 'new contact form custom fields', with_hidden_elements: true do
      person; company;
      visit '/easy_contacts/new'
      expect( find("#easy_contact_type_id_#{person.id}") ).to be_checked

      expect(page).not_to have_css("#easy_contact_custom_field_values_#{cf1.id}_")

      find(:select, 'non-primary-custom-fields-select').find("option[value='#{cf1.id}']").select_option

      within(:css, '#contact-type-attributes') do
        find_field("easy_contact_custom_field_values_#{cf1.id}_")
        find("#easy_contact_#{cf1.id}_container").find('a.icon-del').click
      end

      expect(page).not_to have_css("#easy_contact_custom_field_values_#{cf1.id}_")
      expect(page).to have_css("#non-primary-custom-fields-select option[value*='#{cf1.id}']")

      choose("easy_contact_type_id_#{company.id}")
      expect(page).not_to have_css("#easy_contact_custom_field_values_#{cf2.id}_")

      expect(page).to have_css("#non-primary-custom-fields-select option[value*='#{cf2.id}']")
    end
  end

  context 'show contact' do
    let(:personal_easy_contact) { FactoryGirl.create(:personal_easy_contact) }
    let!(:cf_list) { FactoryGirl.create_list(:easy_contact_custom_field, 2, :is_primary => true, :easy_group_id => nil) }

    it 'show all custom fields' do
      type = personal_easy_contact.easy_contact_type
      type.custom_fields = cf_list
      type.save
      visit easy_contact_path(personal_easy_contact)
      expect(page).to have_css('#contact-detail-container .easy-contact-custom-filed-values div.attribute', :count => 2, :visible => false)
    end
  end

  context 'modals' do
    let!(:person) { FactoryGirl.create(:personal_easy_contact_type, is_default: true) }
    let!(:easy_contacts) { FactoryGirl.create_list(:easy_contact, 3) }

    it 'remembers references' do
      visit '/easy_contacts/new'
      page.find('#easy_contact_reference_id_lookup_trigger').click
      wait_for_ajax
      expect(page).to have_css('tbody input[type="checkbox"]', :count => 3)
      expect(page).not_to have_css('tbody input[type="checkbox"]:checked')
      page.first('tbody input[type="checkbox"]').set(true)
      expect(page).to have_css('tbody input[type="checkbox"]:checked', :count => 1)
      page.first('.ui-dialog-buttonpane .button-positive').click
      page.find('#easy_contact_reference_id_lookup_trigger').click
      wait_for_ajax
      expect(page).to have_css('tbody input[type="checkbox"]:checked', :count => 1)
    end
  end

end
