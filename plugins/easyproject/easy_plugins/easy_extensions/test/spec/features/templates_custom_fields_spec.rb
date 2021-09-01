require 'easy_extensions/spec_helper'

feature 'Templates custom fields', js: true, logged: :admin do

  let(:project_cf1) { FactoryGirl.create(:project_custom_field, :field_format => 'date') }
  let(:project_cf2) { FactoryGirl.create(:project_custom_field, :field_format => 'datetime', :max_length => 100) }
  let(:project_cf3) { FactoryGirl.create(:project_custom_field, :field_format => 'int') }
  let(:project) {
    p                     = FactoryGirl.build(:project)
    p.custom_field_values = { project_cf1.id => Date.today, project_cf2.id => { 'date' => Date.today }, project_cf3.id => 1 }
    p.save
    p
  }
  let(:project_template) { project.create_project_templates(:copying_action => :creating_template, :copy_author => true) }

  it 'display date custom field correctly' do
    project
    project_template
    visit show_create_project_template_path(project)

    page.find('.group > span.expander').click
    expect(page).to have_selector("#template_project__custom_field_values_#{project_cf1.id}_#{project.id}")
    expect(page).to have_selector("#template_project__custom_field_values_#{project_cf2.id}_#{project.id}_date")
  end

  it 'uses submitted values after failed creation' do
    project
    project_template
    visit show_create_project_template_path(project)

    page.find('.group > span.expander').click
    page.find("#template_project__custom_field_values_#{project_cf3.id}_#{project.id}").set(5)
    page.find("#template_project_#{project.id}_name").set('')
    page.find('input[type=submit][name=commit]').click
    page.find('.group > span.expander').click

    expect(page.find("#template_project__custom_field_values_#{project_cf3.id}_#{project.id}").value).to eq('5')
  end

end
