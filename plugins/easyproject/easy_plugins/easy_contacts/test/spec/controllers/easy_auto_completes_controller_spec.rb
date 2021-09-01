require 'easy_extensions/spec_helper'

describe EasyAutoCompletesController, logged: :admin do
  context 'free_search' do
    let(:project) { FactoryGirl.create(:project, add_modules: [:easy_contacts], easy_contacts: [easy_contact2]) }
    let!(:easy_contacts) { FactoryGirl.create_list(:easy_contact, 2, parent: parent_contact) }
    let!(:parent_contact) { FactoryGirl.create(:easy_contact, firstname: 'John Coner') }
    let!(:easy_contact1) { FactoryGirl.create(:easy_contact, firstname: 'Max', parent: parent_contact) }
    let!(:easy_contact2) { FactoryGirl.create(:easy_contact, firstname: 'Max John') }

    it '#easy_contacts_with_parents' do
      get :index, params: { autocomplete_action: 'easy_contacts_with_parents', term: 'max', format: 'json' }
      expect(assigns[:entities]).to match_array([easy_contact1])

      get :index, params: { autocomplete_action: 'easy_contacts_with_parents', term: '', format: 'json' }
      expect(assigns[:entities]).to match_array([easy_contact1] + easy_contacts)
    end

    it '#easy_contacts_with_children' do
      get :index, params: { autocomplete_action: 'easy_contacts_with_children', term: 'jo co', format: 'json' }
      expect(assigns[:entities]).to match_array([parent_contact])

      get :index, params: { autocomplete_action: 'easy_contacts_with_children', term: '', format: 'json' }
      expect(assigns[:entities]).to match_array([parent_contact])
    end

    it '#root_easy_contacts' do
      get :index, params: { autocomplete_action: 'root_easy_contacts', term: 'coner', format: 'json' }
      expect(assigns[:entities]).to match_array([parent_contact])

      get :index, params: { autocomplete_action: 'root_easy_contacts', term: '', format: 'json' }
      expect(assigns[:entities]).to match_array([parent_contact, easy_contact2])
    end

    it '#easy_contacts_project_contacts' do
      get :index, params: { autocomplete_action: 'easy_contacts_project_contacts', term: '', project_id: project.id, format: 'json' }
      expect(assigns[:easy_contacts]).to match_array([easy_contact2])

      get :index, params: { autocomplete_action: 'easy_contacts_project_contacts', term: 'under', project_id: project.id, format: 'json' }
      expect(assigns[:easy_contacts]).to match_array([])
    end

    it '#easy_contacts_visible_contacts' do
      get :index, params: { autocomplete_action: 'easy_contacts_visible_contacts', term: '', format: 'json' }
      expect(assigns[:easy_contacts]).to match_array(easy_contacts + [parent_contact] + [easy_contact1] + [easy_contact2])
    end
  end

  context '#assignable_principals_easy_contact' do
    let(:easy_contact) { FactoryBot.create(:easy_contact) }

    it 'assignable_principals contact' do
      get :index, params: { autocomplete_action: 'assignable_principals_easy_contact', format: 'json' }
      expect(response).to be_successful
    end

    it 'assignable_principals contact id' do
      get :index, params: { autocomplete_action: 'assignable_principals_easy_contact', format: 'json', easy_contact_id: easy_contact.id }
      expect(response).to be_successful
    end
  end

  context '#partner_contacts' do
    let!(:partner_contact) { FactoryBot.create(:easy_contact) }

    it do
      with_easy_settings(easy_contacts_partner_type_id: partner_contact.type_id) do
        get :index, params: { autocomplete_action: 'partner_contacts', term: '', format: 'json' }

        expect(assigns[:entities]).to match_array([partner_contact])
      end
    end
  end
end
