require 'easy_extensions/spec_helper'

feature 'lookup custom field', js: true, logged: :admin do
  context 'lookup custom field with entity contact', js: true, js_wait: :long, logged: :admin do
    let(:settings) { HashWithIndifferentAccess.new(:entity_type => 'EasyContact', :entity_attribute => 'link_with_name') }
    let(:easy_contact) { FactoryGirl.create(:easy_contact) }
    let(:easy_contact1) { FactoryGirl.create(:easy_contact) }
    let(:easy_contact2) { FactoryGirl.create(:easy_contact) }
    let(:user) { FactoryGirl.create(:user) }
    let!(:custom_field1) { FactoryGirl.create(:user_custom_field, :field_format => 'easy_lookup', :settings => settings, :multiple => true)}
    let!(:custom_field2) { FactoryGirl.create(:user_custom_field, :field_format => 'easy_lookup', :settings => settings, :multiple => true)}
    let!(:custom_field3) { FactoryGirl.create(:user_custom_field, :field_format => 'easy_lookup', :settings => settings, :multiple => true)}
    scenario 'three same lookup custom fields with same value' do
      easy_contact
      easy_contact1
      easy_contact2
      visit edit_user_path(user)
      page.find("#user_custom_field_values_#{custom_field1.id}__lookup_trigger_container").click
      wait_for_ajax
      page.find('.modal table.entities') # wait
      page.find("input[id='cbx-#{easy_contact.id}'][type='checkbox']").click
      page.find("input[id='cbx-#{easy_contact1.id}'][type='checkbox']").click
      page.find("input[id='cbx-#{easy_contact2.id}'][type='checkbox']").click
      page.find(".button-positive.ui-button").click
      page.find("#user_custom_field_values_#{custom_field2.id}__lookup_trigger_container").click
      wait_for_ajax
      page.find('.modal table.entities') # wait
      page.find("input[id='cbx-#{easy_contact.id}'][type='checkbox']").click
      page.find("input[id='cbx-#{easy_contact1.id}'][type='checkbox']").click
      page.find("input[id='cbx-#{easy_contact2.id}'][type='checkbox']").click
      page.find(".button-positive.ui-button").click
      scroll_to_and_click(page.find("#user_custom_field_values_#{custom_field3.id}__lookup_trigger_container"))
      wait_for_ajax
      page.find('.modal table.entities') # wait
      page.find("input[id='cbx-#{easy_contact2.id}'][type='checkbox']").click
      page.find("input[id='cbx-#{easy_contact1.id}'][type='checkbox']").click
      page.find("input[id='cbx-#{easy_contact.id}'][type='checkbox']").click
      page.find(".button-positive.ui-button").click
      page.find(".button-positive[type='submit']").click
      # Chyba muze byt zavinena metodou ensure_easy_contact, ktera se pokusi ulozit dva totozne zaznami do databaze
      expect(page).to have_selector('.flash.notice')
      expect(user.easy_contacts.count).to eq(3)
    end
  end
end
