require 'easy_extensions/spec_helper'

feature 'Time entries view', js: true, logged: :admin, js_wait: :long do

  let(:project) { FactoryGirl.create(:project, :enabled_module_names => %w(time_tracking issue_tracking), :number_of_issues => 0) }
  let(:roles) { FactoryGirl.create_list(:role, 2) }
  let(:member) { FactoryGirl.create(:member, :project => project, :user => User.current, :roles => roles) }
  let(:user) { FactoryGirl.create(:user, :admin => true) }
  let(:issue) { FactoryGirl.create(:issue, :project => project) }
  let(:project_activity_role) { FactoryGirl.create(:project_activity_role, :project => project, :role => roles[0]) }

  scenario 'time entry range select' do
    setting                              = EasyGlobalTimeEntrySetting.find_or_initialize_by(:role_id => nil)
    original                             = setting.show_time_entry_range_select if setting.show_time_entry_range_select
    setting.show_time_entry_range_select = true
    setting.save
    user

    begin
      with_user_pref(:user_time_entry_setting => 'all') do
        visit new_easy_time_entry_path(:project_id => project)
        page.find("#time_entry_easy_time_entry_range_from option[value='01:00']").select_option
        page.find("#time_entry_easy_time_entry_range_to option[value='03:00']").select_option
        page.execute_script("setEasyAutoCompleteValue('user_id', #{user.id}, '#{user.name}');")
        wait_for_ajax
        expect(page.find('#time_entry_hours').value).to eq('2.0')
      end
    ensure
      if setting
        setting.show_time_entry_range_select = original
        setting.save
      end
    end
  end

  scenario 'time entry range without select' do
    user

    with_user_pref(:user_time_entry_setting => 'all') do
      visit new_easy_time_entry_path(:project_id => project)
      from_css = '#time_entry_easy_time_entry_range_from'
      to_css   = '#time_entry_easy_time_entry_range_to'
      convert_field_type_to_text(from_css)
      convert_field_type_to_text(to_css)
      page.find(from_css).set('07:00')
      page.find(to_css).set('08:00')
      page.execute_script("setEasyAutoCompleteValue('user_id', #{user.id}, '#{user.name}');")
      wait_for_ajax
      expect(page.find('#time_entry_hours').value).to eq('1.0')
    end
  end

  scenario 'html comments' do
    setting                                = EasyGlobalTimeEntrySetting.find_or_initialize_by(role_id: nil)
    original                               = setting.timelog_comment_editor_enabled if setting.timelog_comment_editor_enabled
    setting.timelog_comment_editor_enabled = true
    setting.save
    begin
      user

      with_settings({ 'text_formatting' => 'HTML' }) do
        visit new_easy_time_entry_path(project_id: project)
        wait_for_ajax
        page.find("#container_projects .easy-autocomplete-tag .ui-button").click
        expect(page).to have_css('.ui-menu-item', text: project.name)
        page.execute_script("setEasyAutoCompleteValue('user_id', #{user.id}, '#{user.name}');")
        wait_for_ajax
        page.find("#container_projects .easy-autocomplete-tag .ui-button").click
        expect(page).to have_css('.ui-menu-item', text: project.name)
        expect(page).to have_css('#cke_time_entry_comment')
      end
    ensure
      if setting
        setting.timelog_comment_editor_enabled = original
        setting.save
      end
    end
  end

  scenario 'time entry activities by role select' do
    member; project_activity_role

    with_easy_settings(:enable_activity_roles => true) do
      visit new_easy_time_entry_path(:project_id => project)
      role_select              = page.find('#user_role_id_time_entry')
      role_with_activity_id    = roles[0].id
      role_without_activity_id = roles[1].id

      # user.memberships.first.roles reverse order of user.members.first.roles
      page.find("option[value=\'#{role_with_activity_id}\']").select_option

      expect(page).to have_css(("option[value=\'#{role_without_activity_id}\']"))
      expect(page).to have_css(("option[selected=\'selected\'][value=\'#{role_with_activity_id}\']"))
      expect(page).not_to have_css('.timeentry-activities .nodata')

      role_select.find('option[value=\'xAll\']').select_option
      wait_for_ajax
      expect(page).not_to have_css('.timeentry-activities .nodata')

      role_select.find("option[value=\'#{role_with_activity_id}\']").select_option
      wait_for_ajax
      expect(page).not_to have_css('.timeentry-activities .nodata')

      role_select.find("option[value=\'#{role_without_activity_id}\']").select_option
      wait_for_ajax
      expect(page).to have_css('.timeentry-activities .nodata')
    end
  end

  scenario 'prefill time entry attributes' do
    visit issue_path(issue)
    page.find('#sidebar .menu-more-container > a.menu-expander').click
    page.find('a.icon-time-add').click
    wait_for_ajax
    expect(page).to have_css("#user_id[value='#{User.current.id}']", visible: false)
    expect(page).to have_css("#project_id[value='#{issue.project.id}']", visible: false)
    expect(page).to have_css("#issue_id[value='#{issue.id}']", visible: false)
  end

  scenario 'time entry activities by role select in modal' do
    member; project_activity_role

    with_easy_settings(:enable_activity_roles => true) do
      visit issue_path(issue)
      page.find('#sidebar .menu-more-container > a.menu-expander').click
      page.find('a.icon-time-add').click
      wait_for_ajax

      within page.find('#ajax-modal') do
        role_select              = page.find('#user_role_id_time_entry')
        role_with_activity_id    = roles[0].id
        role_without_activity_id = roles[1].id

        # user.memberships.first.roles reverse order of user.members.first.roles
        page.find("option[value=\'#{role_with_activity_id}\']").select_option

        expect(page).to have_css(("option[value=\'#{role_without_activity_id}\']"))
        expect(page).to have_css(("option[selected=\'selected\'][value=\'#{role_with_activity_id}\']"))
        expect(page).not_to have_css('.timeentry-activities .nodata')

        role_select.find('option[value=\'xAll\']').select_option
        wait_for_ajax
        expect(page).not_to have_css('.timeentry-activities .nodata')

        role_select.find("option[value=\'#{role_with_activity_id}\']").select_option
        wait_for_ajax
        expect(page).not_to have_css('.timeentry-activities .nodata')

        role_select.find("option[value=\'#{role_without_activity_id}\']").select_option
        wait_for_ajax
        expect(page).to have_css('.timeentry-activities .nodata')
      end
    end
  end

end
