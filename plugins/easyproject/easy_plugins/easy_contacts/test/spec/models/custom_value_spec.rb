require 'easy_extensions/spec_helper'

describe CustomValue, :logged => :admin do

  let(:project) { FactoryGirl.build(:project) }
  let(:settings) { HashWithIndifferentAccess.new(:entity_type => 'EasyContact', :entity_attribute => 'link_with_name') }
  let(:custom_field) { FactoryGirl.create(:project_custom_field, :field_format => 'easy_lookup', :settings => settings)}
  let(:easy_contact) { FactoryGirl.create(:easy_contact) }

  it 'ensure easy contact' do
    project.safe_attributes = {'custom_field_values' => {custom_field.id.to_s => easy_contact.id.to_s}}
    project.save!; project.reload
    expect(project.custom_values.pluck(:custom_field_id, :value)).to include([custom_field.id, easy_contact.id.to_s])
    expect(project.easy_contact_ids).to include(easy_contact.id)

    new_project = Project.copy_from(project)
    new_project.name = 'test'
    new_project.save!
    new_project.reload
    expect(new_project.custom_values.pluck(:custom_field_id, :value)).to include([custom_field.id, easy_contact.id.to_s])
    expect(new_project.easy_contact_ids).to include(easy_contact.id)
  end

end
