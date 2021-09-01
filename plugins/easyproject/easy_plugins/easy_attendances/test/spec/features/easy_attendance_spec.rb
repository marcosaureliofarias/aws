require 'easy_extensions/spec_helper'

feature 'easy attendance', :js => true, :logged => :admin do
  let(:default_activity) { FactoryGirl.create(:easy_attendance_activity) }
  let(:vacation_activity)  { FactoryGirl.create(:vacation_easy_attendance_activity, :approval_required => false) }
  let(:date)  { '2015-06-01' }
  let(:date2) { '2015-06-02' }
  let(:from)  { '09:00' }
  let(:to)    { '18:00' }
  let(:arrival_css)   { '#easy_attendance_form_datetime_inputs .time-select-arrival'   }
  let(:departure_css) { '#easy_attendance_form_datetime_inputs .time-select-departure' }

  def disable_read_only(css = nil)
    css ||= '#easy_attendance_form_datetime_inputs .date-select'
    wait_for_ajax
    page.execute_script("$('#{css}').attr('readOnly', false);")
  end

  def visit_list(from, to)
    visit easy_attendances_path(:tab => 'list', :arrival => "#{from}|#{to}", :group_by => '', :set_filter => '1')
  end

  before(:each) { User.current.language = :cs }

  context 'default' do
    before(:each) do
      default_activity
      visit new_easy_attendance_path
      page.find("#easy_attendance_easy_attendance_activity_id").find(:option, default_activity.name).select_option
      disable_read_only
      page.find('#easy_attendance_form_datetime_inputs .date-select').set(date)
      convert_field_type_to_text(arrival_css)
      convert_field_type_to_text(departure_css)
      page.find(arrival_css).set(from)
      wait_for_ajax
      page.find(departure_css).set(to)
    end

    scenario '1 day' do
      page.find("input[type='submit']").click
      wait_for_ajax
      visit_list(date, date)
      expect(page).to have_css('.entities tbody tr', :count => 1)
      expect(page.find('.entities tbody .arrival')).to have_content(from)
      expect(page.find('.entities tbody .departure')).to have_content(to)
    end

    scenario '2 days' do
      page.find('#is_repeating').click
      wait_for_ajax
      page.find('input#departure_date').fill_in(with: date2)
      page.find("input[type='submit']").click
      wait_for_ajax
      visit_list(date, date2)
      wait_for_ajax
      expect(page).to have_css('.entities tbody tr', :count => 2)
      page.all('.entities tbody .arrival').each { |arrival| expect(arrival).to have_content(from) }
      page.all('.entities tbody .departure').each { |departure| expect(departure).to have_content(to) }
    end
  end

  context 'multi' do
    let(:users) { FactoryBot.create_list(:user, 2) }

    def create_attendances
      page.find('.today .easy-attendance-calendar-add-quick-event').click
      wait_for_ajax
      user_ids = users.map(&:id).join(', ')
      page.execute_script("$('.user-select input.ui-autocomplete-input').easymultiselect('setValue', [#{user_ids}]);")
      page.find('.button-positive.modal-submit').click
      wait_for_ajax
    end

    scenario 'create' do
      with_time_travel(0, now: Date.new(2015, 2, 4).to_time) do
        expect(EasyAttendance.where(user_id: users).count).to eq(0)
        visit easy_attendances_path
        create_attendances
        expect(EasyAttendance.where(user_id: users).count).to eq(2)
        create_attendances
        expect(page).to have_css('#errorExplanation')
      end
    end
  end

  context 'midnight' do
    scenario '2359' do
      skip 'unstable'
      midnight = '23:59'
      default_activity
      visit new_easy_attendance_path
      page.find("#easy_attendance_easy_attendance_activity_id").find(:option, default_activity.name).select_option
      disable_read_only
      page.find('#easy_attendance_form_datetime_inputs .date-select').set(date)
      convert_field_type_to_text(arrival_css)
      convert_field_type_to_text(departure_css)
      page.find(arrival_css).set(from)
      wait_for_ajax
      page.find(departure_css).set(midnight)
      page.find("input[type='submit']").click
      wait_for_ajax
      visit_list(date, date)
      expect(page).to have_css('.entities tbody tr', :count => 1)
      expect(page.find('.entities tbody .arrival')).to have_content(from)
      expect(page.find('.entities tbody .departure')).to have_content(midnight)
      visit edit_easy_attendance_path(EasyAttendance.last)
      page.find("input[type='submit']").click
      expect(page).to have_css('.flash.notice')
    end
  end

  context 'detailed report' do
    scenario 'show' do
      visit detailed_report_easy_attendances_path
      expect(page).to have_css('#tab-detailed_report.selected')
      expect(page).to have_css('table.entities')
    end
  end

  context 'vacation' do
    before(:each) do
      vacation_activity
      visit new_easy_attendance_path
      page.find("#easy_attendance_easy_attendance_activity_id").find(:option, vacation_activity.name).select_option
      disable_read_only('#arrival_date')
      page.find('#arrival_date').set(date)
    end

    scenario 'forenoon' do
      page.find("#easy_attendance_range_#{EasyAttendance::RANGE_FORENOON}").click
      page.find('#departure_date').set(date)
      page.find("input[type='submit']").click
      wait_for_ajax
      visit_list(date, date)
      expect(page).to have_css('.entities tbody tr', :count => 1)
      expect(page.find('.entities tbody .arrival')).to have_content(from)
      expect(page.find('.entities tbody .departure')).to have_content('13:00')
    end

    scenario 'afternoon' do
      page.find("#easy_attendance_range_#{EasyAttendance::RANGE_AFTERNOON}").click
      page.find('#departure_date').set(date)
      page.find("input[type='submit']").click
      wait_for_ajax
      visit_list(date, date)
      expect(page).to have_css('.entities tbody tr', :count => 1)
      expect(page.find('.entities tbody .arrival')).to have_content('14:00')
      expect(page.find('.entities tbody .departure')).to have_content('18:00')
    end

    scenario 'fullday' do
      page.find("#easy_attendance_range_#{EasyAttendance::RANGE_FULL_DAY}").click
      page.find('#departure_date').set(date)
      page.find("input[type='submit']").click
      wait_for_ajax
      visit_list(date, date)
      expect(page).to have_css('.entities tbody tr', :count => 1)
      expect(page.find('.entities tbody .arrival')).to have_content(from)
      expect(page.find('.entities tbody .departure')).to have_content('17:00')
    end

    scenario 'fullday 2 days' do
      page.find("#easy_attendance_range_#{EasyAttendance::RANGE_FULL_DAY}").click
      page.find('#departure_date').set(date2)
      page.find("input[type='submit']").click
      wait_for_ajax
      visit_list(date, date2)
      expect(page).to have_css('.entities tbody tr', :count => 2)
      page.all('.entities tbody .arrival').each { |arrival| expect(arrival).to have_content(from) }
      page.all('.entities tbody .departure').each { |departure| expect(departure).to have_content('17:00') }
    end
  end

  context 'specify time' do
    let(:vacation_activity1) { FactoryGirl.create(:vacation_easy_attendance_activity, approval_required: false, use_specify_time: false) }
    let(:vacation_activity2) { FactoryGirl.create(:vacation_easy_attendance_activity, approval_required: false, use_specify_time: true) }
    let(:easy_attendance) { FactoryGirl.create(:easy_attendance, easy_attendance_activity: vacation_activity1, range: EasyAttendance::RANGE_FORENOON) }

    scenario 'change range to interval' do
      vacation_activity1
      vacation_activity2
      visit edit_easy_attendance_path(easy_attendance)
      expect(page.find('#easy_attendance_easy_attendance_activity_id').value).to eq(vacation_activity1.id.to_s)
      page.find("#easy_attendance_easy_attendance_activity_id").find(:option, vacation_activity2.name).select_option
      wait_for_ajax
      expect(page.find('.time-select-departure').value).to include('18')
      page.find("input[type='submit']").click
      visit edit_easy_attendance_path(easy_attendance)
      expect(page.find('#easy_attendance_easy_attendance_activity_id').value).to eq(vacation_activity2.id.to_s)
      expect(page.find('.time-select-departure').value).to include('18')
    end
  end
end
