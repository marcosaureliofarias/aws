require 'easy_extensions/spec_helper'

feature 'Easy Calendar', js: true, logged: :admin do
  scenario 'add to my page' do
    visit '/my/page_layout'
    within '#list-top' do
      select I18n.t(:'easy_pages.modules.easy_calendar'), :from => "module_id"
    end
    wait_for_ajax
    visit '/'
    expect( page ).to have_text(I18n.t(:'easy_pages.modules.easy_calendar'))
  end

  context 'with existing page module' do

    let!(:page_module) do
      EasyPageZoneModule.create!(
        easy_pages_id: 1,
        easy_page_available_zones_id: 1,
        easy_page_available_modules_id: 43,
        user_id: User.current.id,
        settings: HashWithIndifferentAccess.new({enabled_calendars: ['easy_meeting_calendar'],
            display_from: '9:00', display_to: '20:00', defaultView: 'agendaWeek'})
      )
    end
    let(:availability_users) { FactoryGirl.create_list(:user, 3) }

    def open_meeting_dialog
      page.find("tr.fc-week > td[data-date='#{Date.today}']").click
      wait_for_ajax
    end

    scenario 'zoom switching' do
      visit '/'
      expect(page).to have_css('.fc-view-month')

      page.execute_script('$(".easy-cal-month").trigger("click")')
      expect(page).to have_css('.fc-view-month')

      page.execute_script('$(".easy-cal-day").trigger("click")')
      expect(page).to have_css('.fc-view-agendaDay')

      page.execute_script('$(".easy-cal-week").trigger("click")')
      expect(page).to have_css('.fc-view-agendaWeek')
    end

    scenario 'opening meeting dialog' do
      visit '/'
      open_meeting_dialog
      expect(page).to have_css('.new-event-dialog')

      today = Date.today
      expect(page.find('#easy_meeting_start_time_date').value).to eq(today.to_param)
      expect(page.find('#easy_meeting_end_time_date').value).to eq(today.to_param)
    end

    scenario 'meeting dialog validations' do
      visit '/'
      open_meeting_dialog
      click_button I18n.t(:button_save)
      wait_for_ajax
      err = I18n.t(:field_name)
      err << ' ' << I18n.t(:'activerecord.errors.messages.blank')
      expect(page).to have_text(err)
    end

    scenario 'correct range' do
      visit '/'
      open_meeting_dialog
      fill_in('easy_meeting_name', :with => 'timezone meeting')
      page.find('#easy_meeting_all_day').click
      expect(page.find('#easy_meeting_start_time_time').value).to eq('00:00')
      expect(page.find('#easy_meeting_end_time_time').value).to eq('23:59')
      click_button I18n.t(:button_save)
      wait_for_ajax
      expect(page.find('.fc-event-time')).to have_content('0:00')
    end

    scenario 'remembering selected availability users' do
      availability_users
      visit '/'
      # ac_id = "easy-calendar-module_inside_#{page_module.id}-user-select_autocomplete"
      hidden_id = "easy-calendar-module_inside_#{page_module.id}-user-select"
      wait_for_late_scripts
      availability_users.each do |u|
        page.execute_script "setEasyAutoCompleteValue('easy-calendar-module_inside_#{page_module.id}-user-select', '#{u.id}', '#{u.name}')"
        page.execute_script "$('##{hidden_id}').val('#{u.id}').change();"
        wait_for_ajax
      end
      visit '/'
      expect(page).to have_css('.easy-cal-selected-users > span', :count => availability_users.count)
    end

    context 'when I am invited to a meeting' do
      let(:invited_by) { FactoryGirl.create(:user) }
      let!(:invited_to){
        FactoryGirl.create(:easy_meeting, {
          author_id: invited_by.id,
          user_ids: [User.current.id],
          start_time: Time.parse("#{Date.today.to_s} 13:00"),
          end_time: Time.parse("#{Date.today.to_s} 14:00")
        })
      }

      scenario 'accept / decline meeting through dialog' do
        visit '/'
        within '#list-top' do
          click_link invited_to.name
        end
        click_button I18n.t(:button_meeting_accept)

        within '#list-top' do
          click_link invited_to.name
        end
        # expect(page).to have_css('span.icon-true', :text => User.current.name)

        click_button I18n.t(:button_meeting_decline)

        # TODO zvyrazneni prijdu/neprijdu
        # expect(page).to have_css('span.icon-false', :text => User.current.name)
      end

      scenario 'display meeting when url is not root' do
        visit '/my/page'
        expect(page).to have_css('.fc-event', count: 1)
      end

    end

  end

end
