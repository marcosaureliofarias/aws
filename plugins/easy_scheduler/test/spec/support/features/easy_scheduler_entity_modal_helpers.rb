module Features
  module EasySchedulerEntityModalHelpers
    shared_context 'scheduler entity modal stuff' do

      def available_tabs
        ['New meeting', 'New allocation', 'New attendance', 'New sales activity']
      end

      # start_date and end_date are strings like '2018-05-15 08:00'
      def trigger_entity_modal_open(start_date, end_date)
        start_date = User.current.user_time_in_zone(start_date).to_datetime
        end_date = User.current.user_time_in_zone(end_date).to_datetime
        script = <<-JS.squish
          if (typeof easyScheduler !== 'underfined') {
            easyScheduler.scheduler.addEventNow('#{start_date}', '#{end_date}');
          };
        JS
        page.execute_script(script)
      end

      def trigger_all_day_event_modal_open(date, count = 1)
        start_date = date + ' 00:00'
        end_date = (date.to_date + 1.day).to_s + ' 00:00'
        script = <<-JS.squish
          if (typeof easyScheduler !== 'underfined') {
            var id = easyScheduler.scheduler.addEvent('#{start_date}', '#{end_date}');
            var ev = easyScheduler.scheduler.getEvent(id);
            ev._length = 1;
            easyScheduler.scheduler.showLightbox(id);
          };
        JS
        page.execute_script(script)
      end

      def set_tab(tab_id)
        script = <<-JS.squish
          if (typeof localStorage !== "undefined") {
            localStorage.setItem('easy_scheduler_modal_tabs-tab', '#{tab_id}');
          };
        JS
        page.execute_script(script)
      end

      def save_entity
        within('.ui-dialog-buttonset') do
          page.find('button#calendar_modal_button_save').click
        end
        sleep 5 #wait_for_ajax
      end

      def create_entity(entity, date, start_hour, end_hour)
        case entity
        when 'allocation'
          project = FactoryGirl.create(:project, members: [User.current], add_modules: ['easy_gantt', 'easy_gantt_resources'], number_of_issues: 0)
          issue = FactoryGirl.create(:issue, project_id: project.id, estimated_hours: 24, start_date: date, due_date: date + 4.days, assigned_to_id: User.current.id)
          issue.easy_gantt_resources.delete_all
          FactoryGirl.create(:easy_gantt_resource, issue: issue, hours: 3, date: date)
        when 'meeting'
          FactoryGirl.create(:easy_meeting, user_ids: [User.current.id], start_time: "#{date} #{start_hour}", end_time: "#{date} #{end_hour}")
        when 'easy_attendance'
          FactoryGirl.create(:vacation_easy_attendance, arrival: "#{date} #{start_hour}", departure: "#{date} #{end_hour}", user: User.current)
        when 'easy_entity_activity'
          FactoryGirl.create(:easy_entity_activity, start_time: "#{date} #{start_hour}", end_time: "#{date} #{end_hour}", easy_entity_activity_users: [User.current])
        end
      end

      def click_on_event(date, entity_class)
        # suitable for one existed event per date
        dt = date.strftime('%a, %B %d')
        find(".easy-calendar__day-cell[aria-label='#{dt}'] .dhx_cal_event.#{entity_class} .dhx_body").click
      end

      def right_click_on_event(date, entity_class)
        # suitable for one existed event per date
        dt = date.strftime('%a, %B %d')
        find(".easy-calendar__day-cell[aria-label='#{dt}'] .dhx_cal_event.#{entity_class} .dhx_body").right_click
      end

      def click_on_edit_icon(entity_class)
        execute_script('$(".easy-calendar__event-icons").show()')
        find(".easy-calendar__event-icon.icon_details").click
      end

      def click_on_delete_icon
        execute_script('$(".easy-calendar__event-icons").show()')
        find('.easy-calendar__event-icon.icon_delete').click
      end
    end

    shared_context 'allocation stuff' do
      def create_allocation(issue_start, issue_end, date, start_hour, end_hour)
        project = FactoryGirl.create(:project, members: [User.current], add_modules: ['easy_gantt', 'easy_gantt_resources'], number_of_issues: 0)
        issue = FactoryGirl.create(:issue, project_id: project.id, estimated_hours: 24, start_date: issue_start, due_date: issue_end, assigned_to_id: User.current.id)
        issue.easy_gantt_resources.delete_all
        visit easy_scheduler_path(anchor: "date=#{date}&mode=week")
        set_tab('tab-allocation')
        trigger_entity_modal_open("#{date} #{start_hour}", "#{date} #{end_hour}")
        select_issue(issue)
        save_entity
        issue.reload
        issue.easy_gantt_resources.where(date: date)
      end

      def select_issue(issue)
        within('#calendar_modal span.easy-autocomplete-tag') do
          page.find('.ui-button').click
        end
        wait_for_ajax
        within('.ui-dialog ul.ui-menu') do
          page.find('li.ui-menu-item div', text: issue.to_s).click
        end
      end
    end

    shared_context 'sales activity stuff' do
      let(:date) { '2018-09-15' }
      let(:start_hour) { '10:00' }
      let(:end_hour) { '11:00' }
      before do
        @category = FactoryGirl.create(:easy_entity_activity_category)
        visit easy_scheduler_path(anchor: "date=#{date}&mode=week")
        set_tab("tab-easy_entity_activity")
        trigger_entity_modal_open("#{date} #{start_hour}", "#{date} #{end_hour}")
      end

      def select_entity(entity)
        within('.easy-scheduler-activity-entity-id') do
          page.find('.ui-button').click
        end
        wait_for_ajax

        within('.ui-dialog ul.ui-menu') do
          page.find('li.ui-menu-item div', text: entity.to_s).click if entity.is_a? EasyCrmCase
          page.find('li.ui-menu-item', text: entity.to_s).click if entity.is_a? EasyContact
        end
      end

      def choose_entity(entity_name)
        within('.tab-easy_entity_activity-content') do
          page.choose(entity_name)
          wait_for_ajax
        end
      end

      def create_sales_activity
        crm_case = FactoryGirl.create(:easy_crm_case)
        crm_case.easy_entity_activities.delete_all
        select_entity(crm_case)
        save_entity
        crm_case.reload
        crm_case.easy_entity_activities
      end
    end

    shared_examples 'scheduler modal' do |entity, date, start_hour, end_hour|
      before do
        visit easy_scheduler_path(anchor: "date=#{date}&mode=week")
        set_tab("tab-#{entity}")
        trigger_entity_modal_open("#{date} #{start_hour}", "#{date} #{end_hour}")
      end

      it "#{entity} show" do
        expect(page).to have_css('#calendar_modal')

        expect(page.all('.ui-dialog a[data-tab-id]').map(&:text)).to match_array(available_tabs)

        expect(page.find('.ui-dialog')).to have_css("a.selected[data-tab-id='tab-#{entity}']")

        expect(page.find('.ui-dialog-content')).to have_css(".tab-#{entity}-content form")
      end
    end

    shared_examples 'scheduler event' do |entity, date, start_hour, end_hour, entity_class|
      before do
        @entity = create_entity(entity, date, start_hour, end_hour)
        @labels = { allocation: 'Allocation', meeting: 'Meeting', easy_attendance: 'Attendance', easy_entity_activity: 'Sales activity' }
        visit easy_scheduler_path(anchor: "date=#{date}&mode=week")
      end

      it "#{entity} event exists" do
        expect(page).to have_css(".dhx_cal_event.#{entity_class}")

        hours = ((end_hour.to_time - start_hour.to_time) / 3600).round(1).to_s.gsub(/(\.)0+$/, '')
        expect(page.find('.dhx_cal_event')).to have_text("#{hours}h") #round float
        right_click_on_event(date, entity_class)
        expect(page).to have_css('#calendar_modal_button_delete')
        expect(page).to have_css('#calendar_modal_button_save')
        expect(page).to have_css('#calendar_modal_button_cancel')
        page.find('.ui-dialog-titlebar-close').click
      end

      it "#{entity} delete" do
        click_on_event(date, entity_class)
        expect(page).to have_css('#calendar_modal')
        click_on_delete_icon
        # wait_for_ajax
        sleep 5
        dt = date.strftime('%a, %B %d')
        expect(page).not_to have_selector(".easy-calendar__day-cell[aria-label='#{dt}'] .dhx_cal_event.#{entity_class} .dhx_body")
        reloaded_entity = @entity.class.find_by_id(@entity.id)

        expect(reloaded_entity).to be_nil
      end
    end

    shared_examples 'all-day from month view' do |entity, date|
      include_context 'scheduler entity modal stuff'
      before do
        @dte = date.strftime('%Y-%m-%d')
        if entity == 'easy_attendance'
          @activity = FactoryGirl.create(:easy_attendance, easy_attendance_activity: FactoryGirl.create(:easy_attendance_activity, use_specify_time: true))
        end
        visit easy_scheduler_path(anchor: "date=#{date}&mode=month")
        set_tab("tab-#{entity}")
        trigger_all_day_event_modal_open(@dte)
        @clndr = User.current.current_working_time_calendar
      end

      it "#{entity} event" do
        case entity
        when 'meeting'
          expect(page.find('#easy_meeting_all_day')).to be_checked
          expect(page).to have_selector("input#easy_meeting_start_time_date[value='#{@dte}']")
          expect(page).to have_selector("input#easy_meeting_end_time_date[value='#{@dte}']")
        when 'allocation'
          expect(page).to have_selector("input#allocation_start_time_date[value='#{@dte}']")
          expect(page).to have_selector("input[name='allocation_start_time'][value='#{@clndr.time_from.strftime('%H:%M')}']")
          expect(page).to have_selector("input[name='allocation_end_time'][value='#{@clndr.time_to.strftime('%H:%M')}']")
        when 'easy_attendance'
          expect(page).to have_selector("input#easy_attendance_attendance_date[value='#{@dte}']")
          expect(page).to have_selector("input[name='arrival[time]'][value='#{@clndr.time_from.strftime('%H:%M')}']")
          expect(page).to have_selector("input[name='departure[time]'][value='#{@clndr.time_to.strftime('%H:%M')}']")
        when 'easy_entity_activity'
          expect(page.find('#easy_entity_activity_all_day')).to be_checked
          expect(page).to have_selector("input#easy_entity_activity_start_time_date[value='#{@dte}']")
          expect(page).to have_selector("input[name='easy_entity_activity[start_time][time]'][value='#{@clndr.time_from.strftime('%H:%M')}']")
          expect(page).to have_selector("input[name='easy_entity_activity[end_time][time]'][value='#{@clndr.time_to.strftime('%H:%M')}']")
        end
      end
    end
  end
end

