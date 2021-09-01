require 'easy_extensions/spec_helper'

feature 'user custom field', js: true, logged: :admin do

  let!(:custom_field) { FactoryGirl.create(:user_custom_field, :field_format => 'string', :non_deletable => true, :is_primary => true) }

  # before(:each) do
  #   u = User.current.reload
  #   u.safe_attributes = {'custom_field_values' => {custom_field.id.to_s => 'xxx value'}}
  #   u.save; u.reload
  # end

  def disable_custom_field(cf)
    cf.update_attribute(:disabled, true)
    cf.reload; User.current.reload
  end

  context 'user edit' do
    scenario 'is visible' do
      visit edit_user_path(User.current)
      expect(page).to have_css('#user_form')
      expect(page).to have_css("#user_custom_field_values_#{custom_field.id}_")
    end

    scenario 'can be disabled' do
      disable_custom_field(custom_field)
      visit edit_user_path(User.current)
      expect(page).to have_css('#user_form')
      expect(page).not_to have_css("#user_custom_field_values_#{custom_field.id}_")
    end
  end

  # context 'my account' do
  # scenario 'is visible' do
  #   visit '/my/account'
  #   expect(page).to have_css('#my_account_form')
  #   expect(page).to have_css("#user_custom_field_values_#{custom_field.id}")
  # end
  #
  # scenario 'can be disabled' do
  #   disable_custom_field(custom_field)
  #   visit '/my/account'
  #   expect(page).to have_css('#my_account_form')
  #   expect(page).not_to have_css("#user_custom_field_values_#{custom_field.id}")
  # end

  context 'user detail' do
    let(:user) { FactoryGirl.create(:user) }

    scenario 'show' do
      user.safe_attributes = { 'custom_field_values' => { custom_field.id.to_s => 'xxx value' } }
      expect(user.save).to eq(true)

      visit user_path(user)
      expect(page).to have_css('.character-details')
      expect(page.find('.character-details')).to have_text('xxx value')
    end

    scenario 'show disabled' do
      user.safe_attributes = { 'custom_field_values' => { custom_field.id.to_s => 'xxx value' } }
      expect(user.save).to eq(true)

      disable_custom_field(custom_field)
      visit user_path(user)
      expect(page).to have_css('.character-details')
      expect(page.find('.character-details')).not_to have_text('xxx value')
    end
  end
  # end

  context 'value tree' do

    let!(:project) { FactoryGirl.create(:project) }
    let!(:custom_field) do
      FactoryGirl.create(:issue_custom_field, :as_value_tree, :trackers => project.trackers)
    end
    let!(:value) { custom_field.possible_values[1] }
    let!(:issue) do
      # 0 => Value 1
      # 1 => Value 1 > Value 1.1
      _issue = FactoryGirl.create(:issue, :tracker => project.trackers.first)
      _issue.reload
      _issue.custom_field_values = { custom_field.id.to_s => value }
      _issue.save!
      _issue
    end

    scenario 'grouped' do
      FactoryGirl.create_list(:issue, 2)

      query          = EasyIssueQuery.new
      query.name     = 'query'
      query.group_by = "cf_#{custom_field.id}"
      query.save!

      visit issues_path(query_id: query.id)

      expect(page).to have_css("tr.group[data-group-name='[\"#{value}\"]']")
    end
  end


  context 'custom field', :js => true, :logged => :admin do
    let(:template) { FactoryGirl.create(:project, :easy_is_easy_template => true) }
    let(:custom_field) { FactoryGirl.create(:issue_custom_field, :projects => [template.id]) }

    context 'on update' do
      scenario 'keeps saved for project templates', :without_cache => true do
        expect(custom_field.projects.templates.find(template.id)).to eq(template)

        visit edit_custom_field_path(custom_field)

        expect(page).to have_content(custom_field.name)

        click_button(I18n.t(:button_save))

        expect(page).to have_css('#top-menu') # status 200

        expect(custom_field.projects.templates.find(template.id)).to eq(template)
      end
    end
  end

  context 'grouped lookup custom field', :js => true, :logged => :admin do
    let(:project) { FactoryGirl.create(:project) }
    let(:user_settings) { HashWithIndifferentAccess.new(:entity_type => 'User', :entity_attribute => 'link_with_name') }
    let(:project_settings) { HashWithIndifferentAccess.new(:entity_type => 'Project', :entity_attribute => 'link_with_name') }
    let(:user) { FactoryGirl.create(:user) }
    let(:user_lookup_custom_field) { FactoryGirl.create(:project_custom_field, :field_format => 'easy_lookup', :settings => user_settings, :is_for_all => true, :show_on_list => true, :is_filter => false) }
    let(:project_lookup_custom_field_factory) { FactoryGirl.build(:user_custom_field, :field_format => 'easy_lookup', :settings => project_settings, :is_for_all => true, :show_on_list => true, :is_filter => false) }
    let(:project_lookup_custom_field) { cf = project_lookup_custom_field_factory; cf.save!; cf }
    let(:project_lookup_custom_field_as_filter) { cf = project_lookup_custom_field_factory; cf.is_filter = true; cf.save!; cf }

    def test_grouped_lookup(cf, entity, lookup_entity)
      entity.custom_field_values = { cf.id.to_s => lookup_entity.id }
      entity.save!
      visit polymorphic_path(entity.class, :set_filter => '1', :group_by => "cf_#{cf.id}", :load_groups_opened => '1')
      wait_for_ajax

      entity_css = ".entities tr#entity-#{entity.id}"
      group      = page.find(".entities tr.group[data-group-name='[\"#{lookup_entity.id}\"]']")
      expect(group).to have_content(lookup_entity.name)
      expect(page).to have_css(entity_css)

      is_inside_group = page.evaluate_script("$('##{group[:id]}').index()").to_i < page.evaluate_script("$('#{entity_css}').index()").to_i
      expect(is_inside_group).to eq(true)
    end

    scenario 'on projects' do
      test_grouped_lookup(user_lookup_custom_field, project, user)
    end

    scenario 'on users' do
      test_grouped_lookup(project_lookup_custom_field, user, project)
    end

    scenario 'on users as filter' do
      test_grouped_lookup(project_lookup_custom_field_as_filter, user, project)
    end
  end

  # context 'lookup custom field', js: true, js_wait: :long, logged: :admin do
  #   let(:project) { FactoryGirl.create(:project) }
  #   let(:xsettings) { HashWithIndifferentAccess.new(:entity_type => 'User', :entity_attribute => 'link_with_name') }
  #   let!(:custom_field) { FactoryGirl.create(:project_custom_field, :field_format => 'easy_lookup', :settings => xsettings, :multiple => true) }
  #
  #   scenario 'values' do
  #     visit settings_project_path(project)
  #     page.find("#project_custom_field_values_#{custom_field.id}_lookup_trigger").click
  #     wait_for_ajax
  #     page.first("#ajax-modal input[id^='cbx-'][type='checkbox']").click
  #     page.find('.ui-dialog-buttonset .button-positive').click
  #     expect(page).to have_css("#project_custom_field_values_#{custom_field.id}_lookup_trigger_container .easy-lookup-selected-value-wrapper", :count => 1)
  #     page.find('#save-project-info').click
  #     expect(page).to have_css("#project_custom_field_values_#{custom_field.id}_lookup_trigger_container .easy-lookup-selected-value-wrapper", :count => 1)
  #     page.find("#project_custom_field_values_#{custom_field.id}_lookup_delete_button").click
  #     expect(page).not_to have_css("#project_custom_field_values_#{custom_field.id}_lookup_trigger_container .easy-lookup-selected-value-wrapper")
  #     expect(page).to have_css("#project_custom_field_values_#{custom_field.id}_lookup_trigger_container #project_custom_field_values_#{custom_field.id}-no_value", :count => 1)
  #     page.find('#save-project-info').click
  #     expect(page).not_to have_css("#project_custom_field_values_#{custom_field.id}_lookup_trigger_container .easy-lookup-selected-value-wrapper")
  #   end
  # end

end

context 'user custom field', js: true, js_wait: :long, logged: :admin do
  let(:project) { FactoryGirl.create(:project) }
  let(:custom_field) { FactoryGirl.create(:project_custom_field, :field_format => 'user', :is_for_all => true) }

  scenario 'groups' do
    custom_field
    project.safe_attributes = { 'custom_field_values' => { custom_field.id.to_s => User.current.id } }
    project.save; project.reload
    visit projects_path(:set_filter => '1', :load_groups_opened => '1', :group_by => "cf_#{custom_field.id}")
    wait_for_ajax
    expect(page).to have_css("tr#entity-#{project.id}")
  end
end
