require 'easy_extensions/spec_helper'

feature 'Project meetings calendar', js: true, logged: :admin do

  let(:project) { FactoryGirl.create(:project) }

  scenario 'add to project page' do
    visit project_path(project)
    click_link I18n.t(:label_personalize_page)
    within '#list-top' do
      select I18n.t(:'easy_pages.modules.project_meetings'), from: "module_id"
    end
    wait_for_ajax
    click_link I18n.t(:button_save_easy_page)
    wait_for_ajax

    expect(page.current_path).to eq "/projects/#{project.id}"

    expect( page ).to have_text(I18n.t(:'easy_pages.modules.project_meetings'))
  end

  scenario 'add to project page with display range' do
    visit project_path(project)
    click_link I18n.t(:label_personalize_page)
    within '#list-top' do
      select I18n.t(:'easy_pages.modules.project_meetings'), from: "module_id"
    end
    wait_for_ajax

    from_css = 'input[name*="display_from"]'
    to_css = 'input[name*="display_to"]'
    convert_field_type_to_text(from_css)
    convert_field_type_to_text(to_css)
    page.find(from_css).set('9:00')
    page.find(to_css).set('20:00')
    click_link I18n.t(:button_save_easy_page)
    wait_for_ajax

    expect(page.current_path).to eq "/projects/#{project.id}"

    expect( find('.fc-agenda-slots tr:first-child') ).to have_text('9:00')
    expect( find('.fc-agenda-slots tr:nth-last-child(2)') ).to have_text('19:00')
  end

  context 'with existing project module' do
    let!(:page_module) { EasyPageZoneModule.create!(
      easy_pages_id: 2,
      easy_page_available_zones_id: 4,
      easy_page_available_modules_id: 44,
      entity_id: project.id,
      settings: HashWithIndifferentAccess.new({enabled_calendars: ['easy_meeting_calendar'],
            display_from: '0:00', display_to: '24:00', defaultView: 'agendaWeek'})
    )}
    let(:other_project) { FactoryGirl.create(:project) }

    scenario 'display meetings from current project' do
      start_time = Time.now.change({:hour => 12})
      end_time = Time.now.change({:hour => 13})

      project_meeting       = FactoryGirl.create(:easy_meeting, start_time: start_time, end_time: end_time, project_id: project.id)
      other_project_meeting = FactoryGirl.create(:easy_meeting, start_time: start_time, end_time: end_time, project_id: other_project.id)
      no_project_meeting    = FactoryGirl.create(:easy_meeting, start_time: start_time, end_time: end_time, project_id: nil)

      visit project_path(project)

      expect( page ).to have_css('.fc-event', text: project_meeting.name)
      expect( page ).not_to have_css('.fc-event', text: other_project_meeting.name)
      expect( page ).not_to have_css('.fc-event', text: no_project_meeting.name)

      page.find('.fc-event', text: project_meeting.name).click
      wait_for_ajax
      expect(page).to have_css('.ui-dialog-title', text: project_meeting.name)
      
      visit project_path(project, jump: 'overview')
      wait_for_ajax
      page.find('.fc-event', text: project_meeting.name).click
      wait_for_ajax
      expect(page).to have_css('.ui-dialog-title', text: project_meeting.name)
    end
  end

end
