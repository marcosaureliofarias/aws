require 'easy_extensions/spec_helper'
feature 'User customize easy page', js: true, js_wait: :long do

  let(:project) { FactoryBot.create(:project) }
  let(:issue) { FactoryBot.create(:issue, project: project) }

  def add_tab
    page.find('.add-tab-button').click
    wait_for_ajax
  end

  def remove_last_tab
    page.all('#easy_page_tabs ul > li .icon-del').last.click
    wait_for_ajax
  end

  def check_saved_module_in_zone(zone)
    expect(page).to have_selector("#list-#{zone} .module-content")
  end

  def check_added_module_in_zone(zone)
    expect(page).to have_selector("#list-#{zone} .easy-page-module")
  end

  def create_page_module_as_anonymous_user(path, perm, mod = I18n.t(:noticeboard, :scope => :'easy_pages.modules'))
    role = add_permission(:anonymous, perm)
    visit path
    select_easy_page_module(mod, 'top')
    save_easy_page_modules
    role.remove_permission!(perm)
    role.reload
    User.current.reload
    expect(page).to have_content(mod)
  end

  def add_permission(role, perm)
    role = Role.send(role)
    role.add_permission!(perm)
    role.reload
    User.current.reload
    role
  end

  context 'edit pages as anonymous user' do
    scenario 'my page', logged: false do
      with_settings login_required: 0 do
        create_page_module_as_anonymous_user('/my/page_layout', :manage_my_page)
        visit '/my/page'
        expect(page).to_not have_css('.icon-edit')
      end
    end

    scenario 'project overview', logged: false do
      with_settings login_required: 0 do
        create_page_module_as_anonymous_user("/projects/#{project.id}/personalize_show", :manage_page_project_overview)
        visit "/projects/#{project.id}"
        expect(page).to_not have_css('.icon-edit')
      end
    end

    scenario 'easy calendar', logged: false do
      with_settings login_required: 0 do
        add_permission(:anonymous, :view_easy_calendar)
        create_page_module_as_anonymous_user('/easy_calendar/page_layout', :edit_easy_calendar_layout)
        visit '/easy_calendar'
        expect(page).not_to have_css('.icon-edit')
      end if Redmine::Plugin.installed?(:easy_calendar)
    end

    scenario 'easy crm', logged: false do
      with_settings login_required: 0 do
        add_permission(:anonymous, :view_easy_crms)
        create_page_module_as_anonymous_user('/easy_crm/layout', :manage_easy_crm_page)
        visit '/easy_crm'
        expect(page).to_not have_css('.icon-edit')
      end
    end if Redmine::Plugin.installed?(:easy_crm)
  end


  context 'clone', logged: :admin do
    context 'without tabs' do
      scenario 'mypage' do
        visit '/my/page_layout'
        select_easy_page_module(I18n.t(:news, :scope => :'easy_pages.modules'), 'top')
        page.find('a.icon-duplicate').click
        wait_for_ajax
        save_easy_page_modules
        wait_for_ajax
        expect(page).to have_css('.easy-page-module', count: 2)
      end

      scenario 'template' do
        visit '/easy_page_templates/edit_page_template?id=2'
        select_easy_page_module(I18n.t(:news, :scope => :'easy_pages.modules'), 'top')
        page.find('a.icon-duplicate').click
        wait_for_ajax
        save_easy_page_modules
        wait_for_ajax
        expect(page).to have_css('.easy-page-module', count: 2)
      end
    end

    context 'tabs' do
      scenario 'mypage' do
        visit '/my/page_layout'
        wait_for_ajax
        add_tab
        add_tab
        select_easy_page_module(I18n.t(:news, :scope => :'easy_pages.modules'), 'top')
        page.find('a.icon-duplicate').click
        wait_for_ajax
        expect(page).to have_css("select#tab_id option", count: 2)
        page.find("button[title='#{I18n.t(:button_duplicate)}']").click
        save_easy_page_modules
        wait_for_ajax
        expect(page).to have_css('.easy-page-module', count: 2)
      end

      scenario 'template' do
        visit '/easy_page_templates/edit_page_template?id=2'
        wait_for_ajax
        add_tab
        add_tab
        select_easy_page_module(I18n.t(:news, :scope => :'easy_pages.modules'), 'top')
        page.find('a.icon-duplicate').click
        wait_for_ajax
        expect(page).to have_css("select#tab_id option", count: 2)
        page.find("button[title='#{I18n.t(:button_duplicate)}']").click
        save_easy_page_modules
        wait_for_ajax
        expect(page).to have_css('.easy-page-module', count: 2)
      end
    end
  end


  context 'my-page customization' do
    scenario 'add module noticeboard', :logged => true do
      role = Role.non_member
      role.add_permission!(:manage_my_page)
      role.reload
      with_settings(text_formatting: 'HTML') do
        visit '/my/page_layout'
        select_easy_page_module(I18n.t(:noticeboard, :scope => :'easy_pages.modules'), 'top')
        content = find('.module-content')
        sleep(1) #bad solution of bug with dirty checking... CKEDITOR not ready yet maybe?
        text = 'Some testing text to the noticeboard'
        fill_in_ckeditor(1, :context => '.module-content', :with => text)
        save_easy_page_modules
        expect(page).to have_content(text)
      end
    end

    scenario 'add multiple grouped and sorted query modules', :logged => :admin do
      issue
      visit '/my/page_layout'
      iq = I18n.t(:issue_query, :scope => :'easy_pages.modules')
      select_easy_page_module(iq, 'top')
      wait_for_ajax(30)
      page.find('.easy-query-output-list input[value="list"]').click
      page.first(".sort-container select option[value='category']").select_option
      wait_for_ajax
      select_easy_page_module(iq, 'top')
      page.first('.easy-query-output-list input[value="list"]').click
      expect(page).to have_css('.group-container .easy-multiselect-tag-container', count: 2)
      page.execute_script("$('.group-container .easy-multiselect-tag-container input.ui-autocomplete-input').easymultiselect('selectValue', {id: 'project', value: 'Project'});")
      expect(page).to have_css(".load_groups_opened input[type='checkbox']", count: 2)
      page.all(".load_groups_opened input[type='checkbox']").each { |x| x.set(true) }
      save_easy_page_modules
      wait_for_ajax
      page.all('.list.entities').each { |x| expect(x).to have_content(issue.subject) }

#     ### get_epm_easy_query_base_toggling_container_options
#
#      table_view_css = '.module-heading-links .icon-list'
#      expect(page).to have_css(table_view_css, :count => 2, :visible => false)
#      page.all('.list.entities').each { |x| expect(x).to have_content(issue.subject) }
#      table_views = page.all(table_view_css)
#      table_views.each { |x| x.click; wait_for_ajax }
#      page.all('.list.entities').each { |x| expect(x).to have_content(issue.subject) }
#      table_views.reverse_each { |x| x.click; wait_for_ajax }
#      page.all('.list.entities').each { |x| expect(x).to have_content(issue.subject) }
    end

    context 'page zones', :logged => :admin do

      before(:each) { visit '/my/page_layout' }

      ['top', 'left', 'right'].each do |zone|
        scenario "add to #{zone}" do
          select_easy_page_module(I18n.t(:project_news, :scope => :'easy_pages.modules'), zone)
          check_added_module_in_zone(zone)
          save_easy_page_modules
          check_saved_module_in_zone(zone)
        end
      end

#      scenario 'add multiple modules' do
#        zones = ['top', 'left', 'right']
#        zones.each { |zone| select_easy_page_module(I18n.t(:project_news, :scope => :'easy_pages.modules'), zone) }
#        zones.each { |zone| check_added_module_in_zone(zone) }
#        save_easy_page_modules
#        zones.each { |zone| check_saved_module_in_zone(zone) }
#      end
#
#      scenario 'remove and add' do
#        zone = 'right'
#        select_easy_page_module(I18n.t(:project_news, :scope => :'easy_pages.modules'), zone)
#        save_easy_page_modules
#        check_saved_module_in_zone(zone)
#        visit '/my/page_layout'
#        page.find('.easy-page-module .module-heading-links a.icon-del').click
#        expect(page).not_to have_selector("#list-#{zone} .easy-page-module")
#        select_easy_page_module(I18n.t(:project_news, :scope => :'easy_pages.modules'), zone)
#        save_easy_page_modules
#        check_saved_module_in_zone(zone)
#      end
    end

    context 'tabs', :logged => :admin do
      before(:each) { visit '/my/page_layout' }

      scenario 'add' do
        (1..2).each { |i| add_tab; expect(page).to have_selector('#easy_page_tabs ul > li', :count => i) }
      end

      scenario 'remove' do
        (1..2).each { |i| add_tab; expect(page).to have_selector('#easy_page_tabs ul > li', :count => i) }
        page.execute_script('$(".tooltip").show()')
        2.times { remove_last_tab }
        expect(page).not_to have_selector('#easy_page_tabs ul > li')
      end

      scenario 'with attendance' do
        if EasyAttendance.enabled?
          zone = 'top'
          select_easy_page_module(I18n.t(:attendance, :scope => :'easy_pages.modules'), zone)
          (1..2).each { |i| add_tab; expect(page).to have_selector('#easy_page_tabs ul > li', :count => i) }
          save_easy_page_modules
          visit '/my/page_layout'
          within('.module-toggle-button') { find('.expander').click }
          check_saved_module_in_zone(zone)
          expect(page).to have_selector('#easy_page_tabs ul > li', :count => 2)
        end
      end

      context 'documents' do
        let!(:document) { FactoryGirl.create(:document) }

        scenario 'sorted by date' do
          select_easy_page_module(I18n.t(:documents, :scope => :'easy_pages.modules'), 'top')
          page.find('[id$=_sort_by]').find('[value=\'date\']').select_option
          save_easy_page_modules
          check_saved_module_in_zone('top')
        end
      end

      scenario 'redirect to the selected tab' do
        (1..2).each { |i| add_tab; }
        save_easy_page_modules
        expect(page).to have_css('#tab_2.selected')
      end
    end

  end

  context 'project-page customization', :logged => :admin, :js => true do
#
#    scenario 'add module noticeboard' do
#      with_settings(text_formatting: 'HTML') do
#        visit url_for({:controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true})
#        select_easy_page_module(I18n.t(:noticeboard, :scope => :'easy_pages.modules'), 'top')
#        content = find('.module-content')
#        content.fill_in('Heading', :with => 'TEST')
#        sleep(1) #bad solution of bug with dirty checking... CKEDITOR not ready yet maybe?
#        text = 'Some testing text to the noticeboard'
#        fill_in_ckeditor(1, :context => '.module-content', :with => text)
#        save_easy_page_modules
#        expect( page ).to have_content('TEST')
#        expect( page ).to have_content(text)
#      end
#    end

    scenario 'add module noticeboard unsafe chars' do
      visit url_for({ :controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true })
      select_easy_page_module(I18n.t(:noticeboard, :scope => :'easy_pages.modules'), 'top')
      content = find('.module-content')
      content.fill_in('Heading', :with => 'EASY&TEST<br>')
      save_easy_page_modules

      # p page.find('.module-heading-title').text

      expect(page).to have_css('.module-heading-title', text: 'EASY&TEST')
    end

    scenario 'add module generic gauge' do
      visit url_for({ :controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true })
      select_easy_page_module(I18n.t(:generic_gauge, :scope => :'easy_pages.modules'), 'top')
      gauge_name = page.first('input[id^="generic_gauge_"]')
      gauge_type = page.first('select[id^="generic_gauge_"]')
      gauge_name.set('hi')
      gauge_type.find('[value=easy_issue_query]').select_option
      wait_for_ajax
      expect(page).not_to have_css(".easyquery-filters select option[value='project_id']")
      save_easy_page_modules
      expect(page).to have_css('.module-heading', :text => 'hi', :visible => false)
    end

    scenario 'add module report' do
      epage           = EasyPage.find_by(page_name: 'project-overview')
      zone            = EasyPageZone.find_by(zone_name: 'top-left')
      available_zone  = EasyPageAvailableZone.find_by(easy_pages_id: epage.id, easy_page_zones_id: zone.id)
      modul           = EasyPageModule.find_by(type: 'EpmReportQuery')
      available_modul = EasyPageAvailableModule.find_by(easy_pages_id: epage.id, easy_page_modules_id: modul.id)
      EasyPageZoneModule.create!(
          easy_pages_id:                  epage.id,
          easy_page_available_zones_id:   available_zone.id,
          easy_page_available_modules_id: available_modul.id,
          entity_id:                      project.id,
          settings:                       {
              "easy_query_type": "EasyProjectQuery",
              "set_filter":      "1",
              "query_type":      "2",
              "outputs":         ["report"],
              "settings":        { "period":            "month", "report_group_by": ["author", "created_on"],
                                   "report_sum_column": ["", ""] } }
      )

      visit project_path(project)
      expect(page).to have_css('.module-heading-title', text: '(1)')
    end

    scenario 'add module dynamic generic gauge' do
      visit url_for({ :controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true })
      select_easy_page_module(I18n.t(:generic_gauge, :scope => :'easy_pages.modules'), 'top')
      page.find("input[value='dynamic_range']").set(true)
      needle_type = page.find('select[id$="needle_easy_query_klass"]')
      range_type  = page.find('select[id$="range_easy_query_klass"]')
      needle_type.find('[value=easy_issue_query]').select_option
      wait_for_ajax
      range_type.find('[value=easy_issue_query]').select_option
      wait_for_ajax
      filter = page.first('select[id$="add_filter_select"]')
      filter.first("[value='assigned_to_id']").select_option
      wait_for_ajax
      expect(page).to have_css('input[name$="[values][assigned_to_id][]"]')
      save_easy_page_modules
      page.find('.module-heading .icon-edit').click
      wait_for_ajax
      expect(page).to have_css('input[name$="[values][assigned_to_id][]"]', count: 1)
    end

    scenario 'add module project description' do
      visit url_for({ :controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true })
      select_easy_page_module(I18n.t(:project_info, :scope => :'easy_pages.modules'), 'top')
      save_easy_page_modules
      expect(page).to have_css('.module-heading')
    end

    scenario 'add module new issue only required fields' do
      visit url_for({ :controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true })
      select_easy_page_module(I18n.t(:issues_create_new, :scope => :'easy_pages.modules'), 'top')
      page.find(".my-page-issue-query-select select option[value='only_required']").select_option
      save_easy_page_modules
      expect(page).to have_css('.issue-subject-field')
    end

  end

  context 'page modules', :logged => :admin, :slow => true do
    url_map = { 'my-page'                      => '/my/page_layout',
                'project-overview'             => '/projects/project_id/personalize_show',
                'easy-money-projects-overview' => '/easy_money/page_layout'
    }
    EasyPage.preload(:modules => :module_definition).each do |easy_page|
      easy_page.available_modules.each do |m|
        if (url = url_map[easy_page.page_name])
          it "add module #{m.module_definition.type} to page #{easy_page.page_name}" do
            if !m.module_definition.module_allowed?
              pending 'module is disabled'
              raise
            end
            edit_url = url.include?('project_id') ? url.gsub('project_id', project.id.to_s) : url
            visit edit_url
            select_easy_page_module(m.module_definition.translated_name, 'top')
            expect(page).to have_css('.easy-page-module.box')
            save_easy_page_modules
            wait_for_ajax
            expect(page).to have_css('.easy-page-module')
            visit edit_url
            wait_for_ajax
            expect(page).to have_css('.easy-page-module.box')
          end
        end
      end
    end
  end

  context 'page template modules', :logged => :admin do

    scenario 'show easy pages' do
      visit '/easy_pages'
      expect(page).to have_css('table.list')
      visit '/easy_page_templates/edit_page_template?id=1'
      expect(page).to have_css('.save-modules-back')
      visit '/easy_page_templates/show_page_template?id=1'
      expect(page).to have_css('.customize-button')
    end

    # todo test all templates
    scenario 'add module template project team from filter' do
      visit '/easy_page_templates/edit_page_template?id=2'
      select_easy_page_module(I18n.t(:users_query, :scope => :'easy_pages.modules'), 'top')
      expect(page).to have_css('.easy-page-module-form')
      save_easy_page_modules
      wait_for_ajax
      expect(page).to have_css('.easy-page-module')
    end
  end

  context 'duplication', logged: :admin do

    # Duplicate user home page with all modules
    scenario 'regular homepage' do
      heading_name  = 'Easy page noticeboard name'
      template_name = 'Easy page template test'

      visit '/my/page_layout'
      select_easy_page_module(I18n.t(:noticeboard, :scope => :'easy_pages.modules'), 'top')
      noticeboard_heading = page.find(:xpath, '//input[contains(@id, "noticeboard_") and contains(@id, "_heading")]')
      noticeboard_heading.set(heading_name)
      save_easy_page_modules

      visit '/my/page_layout'
      page.find('.easy-page-toolbar a', text: Regexp.new("#{I18n.t(:button_easy_page_create_template)}$", 'i')).click
      page.fill_in('easy_page_template[template_name]', with: template_name)
      page.find('.form-actions input[type="submit"]').click
      sleep 5

      page_template = EasyPageTemplate.find_by_template_name(template_name)
      expect(page_template).to be_a(EasyPageTemplate)

      visit easy_page_templates_show_page_template_path(id: page_template.id)
      heading = page.first('.module-heading')
      expect(heading).to have_content(heading_name)
    end
  end

  context 'chart module', logged: :admin do

    scenario 'add additional query' do
      visit '/my/page_layout'
      select_easy_page_module(I18n.t(:bar_chart_query, :scope => :'easy_pages.modules'), 'top')
      page.find('.easy-query-type').select(I18n.t(:easy_attendance_query, scope: [:easy_query, :name]))
      wait_for_ajax
      page.find('input[id$="query_name"]').set('Bar test')
      page.find('.additional-data-series').click
      wait_for_ajax
      page.find('select[id$="easy_query_type2"]').select(I18n.t(:easy_issue_query, scope: [:easy_query, :name]))
      expect(page).to have_css('.easy-query-filters-field', count: 2)
      save_easy_page_modules
      expect(page).to have_text('Bar test')
    end

  end
  context 'calendar listing', logged: :admin do

    let(:activity) { FactoryBot.create(:time_entry_activity, name: 'work', projects: [project]) }
    scenario 'time entry' do
      activity
      project
      visit '/my/page_layout'
      select_easy_page_module(I18n.t(:timelog_calendar, scope: 'easy_pages.modules'), 'top')
      save_easy_page_modules
      page.find('.timelog-calendar-container .easy-calendar-listing-links .prev').click
      wait_for_ajax
      page.find('.timelog-calendar-container .easy-calendar').first('.day-content a.icon-time-add', visible: false).click
      page.fill_in 'time_entry_hours', with: 5
      page.choose('work')
      page.find_button(I18n.t(:button_create)).click
      wait_for_ajax
      expect(current_path).to eq('/')
      expect(page.find('.timelog-calendar-container .easy-calendar').first('.day-content').text).to include('5.00 h')
    end

    scenario 'attendance' do
      if EasyAttendance.enabled?
        visit '/my/page_layout'
        select_easy_page_module(I18n.t(:attendance, scope: 'easy_pages.modules'), 'top')
        save_easy_page_modules
        cweek = page.find('.easy-attendances .period').text
        page.find('.easy-attendances .easy-calendar-listing-links .prev').click
        wait_for_ajax
        prev_cweek = page.find('.easy-attendances .period').text
        expect(cweek).not_to eq(prev_cweek)
        page.find('.easy-attendances .easy-calendar').first('.calendar-actions a.easy-attendance-calendar-add-quick-event', visible: false).click
        page.find_button(I18n.t(:button_create)).click
        wait_for_ajax
        expect(page.find('.easy-attendances .period').text).to eq(prev_cweek)
        expect(page.find('.easy-attendance-calendar-item').text).to include(User.current.name)
      end
    end
  end

end
