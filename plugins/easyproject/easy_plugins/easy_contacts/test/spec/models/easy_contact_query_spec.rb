require 'easy_extensions/spec_helper'

describe EasyContactQuery do

  let(:project) { FactoryGirl.create(:project) }
  let(:easy_contact_type) { FactoryGirl.create(:easy_contact_type) }
  let(:easy_user_type) { FactoryGirl.create(:easy_user_type, easy_contact_types: [easy_contact_type]) }
  let(:easy_contact) { FactoryGirl.create(:easy_contact, :personal, :with_random_address, {easy_contact_type: easy_contact_type, author: User.anonymous}) }
  let(:role) { FactoryGirl.create(:role, easy_contacts_visibility: 'own') }
  let(:role2) { FactoryGirl.create(:role, easy_contacts_visibility: 'all') }

  context 'visible condition', logged: true do
    before(:each) do
      easy_contact
      User.current.easy_user_type.easy_contact_types << easy_contact_type
    end

    it 'all and own' do
      role.add_permission! :view_easy_contacts
      role2.add_permission! :view_easy_contacts
      project.members << Member.new(project: project, principal: User.current, roles: [role, role2])
      User.current.reload
      expect(EasyContact.visible.to_a).to eq([easy_contact])
    end

    it 'all' do
      role2.add_permission! :view_easy_contacts
      project.members << Member.new(project: project, principal: User.current, roles: [role2])
      User.current.reload
      expect(EasyContact.visible.to_a).to eq([easy_contact])
    end
    
    it 'own' do
      role.add_permission! :view_easy_contacts
      project.members << Member.new(project: project, principal: User.current, roles: [role])
      User.current.reload
      expect(EasyContact.visible.to_a).to be_empty
    end
  end

  context 'with project' do
    it '#projects_for_select_with_current' do
      query = described_class.new(project: project)
      expect(query.available_filters["xproject_id"][:values].call).to include(["<< #{I18n.t(:label_current)} >>", 'current'])
    end
  end

  context 'without project' do
    it '#projects_for_select_with_current' do
      query = described_class.new
      expect(query.available_filters["xproject_id"][:values].call).to eq([])
    end
  end

end