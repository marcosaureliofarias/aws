require 'easy_extensions/spec_helper'

feature 'get projects settings', :logged => true do

  let(:project) { FactoryGirl.create(:project, :author_id => User.current.id) }

  it 'permission only manage versions' do
    Role.non_member.add_permission! :manage_versions
    Role.non_member.add_permission! :edit_own_projects

    visit settings_project_path(project)
    expect(page).to have_css('#top-menu') # status 200
  end

  it 'permission only edit own project' do
    Role.non_member.add_permission! :edit_own_projects

    visit settings_project_path(project)

    expect(page).to have_text(I18n.t(:label_information_plural))
  end

  it 'project info', :js => true, :logged => :admin do
    visit settings_project_path(project, :tab => 'info')

    expect(page).to have_css('#tab-info.selected')
  end

  context 'members' do
    context 'when members of group' do
      let!(:groups) { FactoryGirl.create_list(:group, 2) }
      let!(:member_group) { FactoryGirl.create(:member, :project => project, :principal => groups.last) }
      let!(:user) { FactoryGirl.create(:user) }

      it 'are listed after the group', :members => true, :js => true, :logged => :admin do
        groups.each { |group| user.groups << group }
        project.reload

        visit settings_project_path(project, :tab => 'members')

        body = page.body
        group_name_position = body =~ /#{groups.last.name}/
        user_name_position  = body =~ /#{user.name}/

        expect(group_name_position).to be_an(Integer)
        expect(user_name_position).to be_an(Integer)
        expect(group_name_position).to be < user_name_position
      end
    end
  end

end

#feature 'working with project query (tree)', logged: :admin do
#  let(:projects) { FactoryGirl.create_list(:project, 4) }
#  let!(:project) { FactoryGirl.create(:project, name: 'Vyhledavany projekt', parent_id: projects.first.id) }
#
#  it 'can search given project', js: true do
#    visit projects_path
#    find('#entity_q').set('Vyhledavany')
#    find('#entity_q_button').trigger('click')
#
#    wait_for_ajax
#
#    within('.list.projects') do
#      body = find('tbody')
#      #show parent too
#      expect(body).to have_selector('tr', :count => 1)
#      expect(body).to have_css('td', text: 'Vyhledavany projekt')
#    end
#  end
#end

feature 'create new project', :logged => :admin do
  context 'non-template' do
    let!(:activity_inactive) { FactoryGirl.create(:time_entry_activity, active: false) }
    let!(:parent_project) { FactoryGirl.create(:project, name: 'Parent', project_time_entry_activities: [activity_inactive]) }
    let(:activity_active_default) { FactoryGirl.create(:time_entry_activity, is_default: true, active: true, projects: [parent_project]) }
    let(:activity_active) { FactoryGirl.create(:time_entry_activity, active: true, projects: [parent_project]) }

    it 'inherits nothing' do
      parent_project.project_time_entry_activities = []
      activity_active_default; activity_active
      visit '/projects/new'
      find('#project_name').set('not inheriting')
      page.find("#project_parent_id option[value='#{parent_project.id}']").select_option
      page.uncheck('project_inherit_members')
      page.uncheck('project_inherit_easy_invoicing_settings')
      page.uncheck('project_inherit_time_entry_activities')
      page.uncheck('project_inherit_easy_money_settings')
      find("input[name='commit']").click

      find('.menu-project-menu .settings').click
      find('#tab-activities').click
      expect(find("input#enumerations_#{activity_active_default.id}_active")).to be_checked
      expect(find("input#enumerations_#{activity_active.id}_active")).to be_checked
      expect(find("input#enumerations_#{activity_inactive.id}_active")).not_to be_checked
    end if Redmine::Plugin.installed?(:easy_invoicing) && Redmine::Plugin.installed?(:easy_money)

    it 'inherits all' do
      activity_active
      parent_project.reload.project_time_entry_activities = [activity_inactive]
      activity_active_default
      visit '/projects/new'
      find('#project_name').set('not inheriting')
      page.find("#project_parent_id option[value='#{parent_project.id}']").select_option
      page.check('project_inherit_members')
      page.check('project_inherit_easy_invoicing_settings')
      page.check('project_inherit_time_entry_activities')
      page.check('project_inherit_easy_money_settings')
      find("input[name='commit']").click

      find('.menu-project-menu .settings').click
      find('#tab-activities').click
      expect(find("input#enumerations_#{activity_active_default.id}_active")).to be_checked
      expect(find("input#enumerations_#{activity_active.id}_active")).not_to be_checked
      expect(find("input#enumerations_#{activity_inactive.id}_active")).to be_checked
    end if Redmine::Plugin.installed?(:easy_invoicing) && Redmine::Plugin.installed?(:easy_money)
  end

  context 'from template' do
    let(:template) { FactoryGirl.create(:project, :easy_is_easy_template => true) }

    it 'inherits nothing' do
      visit "/templates/#{template.id}/create"
      page.uncheck('template_inherit_easy_invoicing_settings')
      page.uncheck('template_inherit_time_entry_activities')
      page.uncheck('template_inherit_easy_money_settings')
      find("input[name='commit']").click

      expect(page).to have_css('#top-menu') # status 200
    end if Redmine::Plugin.installed?(:easy_invoicing) && Redmine::Plugin.installed?(:easy_money)

    it 'inherits all' do
      visit "/templates/#{template.id}/create"
      page.check('template_inherit_easy_invoicing_settings')
      page.check('template_inherit_time_entry_activities')
      page.check('template_inherit_easy_money_settings')
      find("input[name='commit']").click

      expect(page).to have_css('#top-menu') # status 200
    end if Redmine::Plugin.installed?(:easy_invoicing) && Redmine::Plugin.installed?(:easy_money)

    context 'with custom field', :js => true do
      let(:cf) { FactoryGirl.create(:project_custom_field, :internal_name => 'internal_cf', :non_deletable => true) }
      let!(:template_with_cv) {
        p                     = FactoryGirl.build(:project, :easy_is_easy_template => true)
        p.custom_field_values = { cf.id => 'test' }
        p.save
        p
      }

      it 'enabled' do
        visit "/templates/#{template_with_cv.id}/create"
        expect(page).to have_css('#project-from-template')
        expect(page).to have_css("[id$='custom_field_values_#{cf.id}_#{template_with_cv.id}']", :visible => false)
      end

      it 'disabled' do
        cf.update_column(:disabled, true)
        visit "/templates/#{template_with_cv.id}/create"
        expect(page).to have_css('#project-from-template')
        expect(page).not_to have_css("[id$='custom_field_values_#{cf.id}_#{template_with_cv.id}']", :visible => false)
      end
    end
  end
end

feature 'project expanders', logged: :admin, js: true do
  let(:root_project) { FactoryGirl.create(:project, name: 'root') }
  let(:subproject) { FactoryGirl.create(:project, name: 'subproject', parent_id: root_project.id) }
  let(:subproject2) { FactoryGirl.create(:project, name: 'subproject2', parent_id: subproject.id) }

  def toggle_expander(root, id)
    root.find(".expander[data-id='#{id}']").click
    wait_for_ajax
  end

  before(:each) do
    subproject2
    visit projects_path
  end

  it 'open' do
    within('.list.projects') do
      body = find('tbody')
      expect(body).to have_selector('tr', :count => 1)
      toggle_expander(body, root_project.id)
      expect(body).to have_selector('tr', :count => 2)
      toggle_expander(body, subproject.id)
      expect(body).to have_selector('tr', :count => 3)
    end
  end

  it 'open and close' do
    within('.list.projects') do
      body = find('tbody')
      expect(body).to have_selector('tr', :count => 1)
      toggle_expander(body, root_project.id)
      toggle_expander(body, subproject.id)
      expect(body).to have_selector('tr', :count => 3)
      toggle_expander(body, root_project.id)
      expect(body).to have_selector('tr', :count => 1)
      toggle_expander(body, root_project.id)
      expect(body).to have_selector('tr', :count => 3)
    end
  end

  it 'preloaded subproject stays closed' do
    within('.list.projects') do
      body = find('tbody')
      expect(body).to have_selector('tr', :count => 1)
      toggle_expander(body, root_project.id)
      toggle_expander(body, subproject.id)
      expect(body).to have_selector('tr', :count => 3)
      toggle_expander(body, subproject.id)
      expect(body).to have_selector('tr', :count => 2)
      toggle_expander(body, root_project.id)
      expect(body).to have_selector('tr', :count => 1)
      toggle_expander(body, root_project.id)
      expect(body).to have_selector('tr', :count => 2)
    end
  end

  context 'cf visibility' do
    let(:cf) { FactoryGirl.create(:project_custom_field) }

    before(:each) do
      Project.all.each do |p|
        p.custom_field_values = { cf.id => 'test' }
        p.save
        p
      end
    end

    it 'admin', logged: :admin do
      visit projects_path(column_names: ['name', "cf_#{cf.id}"])
      within('.list.projects') do
        body = find('tbody')
        expect(page).to have_css(".cf_#{cf.id} .multieditable-parent", count: 1)
        expect(page).to have_css(".cf_#{cf.id}", text: 'test', count: 1)
        toggle_expander(body, root_project.id)
        toggle_expander(body, subproject.id)
        expect(page).to have_css(".cf_#{cf.id} .multieditable-parent", count: 3)
        expect(page).to have_css(".cf_#{cf.id}", text: 'test', count: 3)
      end
    end

    it 'regular', logged: true do
      visit projects_path(column_names: ['name', "cf_#{cf.id}"])
      within('.list.projects') do
        body = find('tbody')
        expect(page).not_to have_css(".cf_#{cf.id} .multieditable-parent")
        expect(page).to have_css(".cf_#{cf.id}", text: 'test', count: 1)
        toggle_expander(body, root_project.id)
        toggle_expander(body, subproject.id)
        expect(page).not_to have_css(".cf_#{cf.id} .multieditable-parent")
        expect(page).to have_css(".cf_#{cf.id}", text: 'test', count: 3)
      end
    end
  end
end

feature 'copy project', logged: :admin, js: true do
  let(:root_project) { FactoryGirl.create(:project) }
  let!(:subproject) { FactoryGirl.create(:project, parent_id: root_project.id) }

  it 'copies project with subprojects' do
    with_easy_settings(:project_display_identifiers => true) do
      visit copy_project_path(root_project)

      page.find('#project_name').set('Copy')
      page.find('#subprojects__identifier').set('ident1')
      page.find('input[type=submit][name=commit]').click

      expect(page).to have_text("#{I18n.t(:notice_successful_create_project_from_template)}")
    end
  end

  it 'failed copy' do
    with_easy_settings(:project_display_identifiers => true) do
      visit copy_project_path(subproject)

      page.find('#project_name').set('Copy')
      page.find('#project_identifier').set(':D')
      page.find('input[type=submit][name=commit]').click

      expect(page).to have_css('#errorExplanation')
    end
  end
end

feature 'project tabs', :logged => :admin do
  let(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking'], :members => [User.current]) }

  it 'show overview' do
    visit project_path(project)
    expect(page).to have_css('#easy-page-layout-service-box-bottom')
    expect(page).to have_css('.overview.selected')
  end

  it 'jump' do
    visit project_path(project, :jump => 'overview')
    expect(page).to have_css('#easy-page-layout-service-box-bottom')
    expect(page).to have_css('.overview.selected')
  end

  it 'jump fallback' do
    visit project_path(project, :jump => 'my_page')
    expect(page).to have_css('#easy-page-layout-service-box-bottom')
    expect(page).to have_css('.overview.selected')
  end

  it 'jump settings' do
    visit project_path(project, :jump => 'settings')
    expect(page).to have_css('#project-settings-edit-container')
    expect(page).to have_css('.settings.selected')
  end

  it 'default page' do
    with_easy_settings(:default_project_page => 'issue_tracking') do
      visit project_path(project)
      expect(page).not_to have_css('#easy-page-layout-service-box-bottom')
      expect(page).to have_css('.issues.selected')
      expect(page).to have_css('#issues')
    end
  end
end
