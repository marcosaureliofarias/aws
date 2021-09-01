module EasyGanttResourcesHelper

  def build_user_events_attributes(user, startdt, enddt)
    startdt = startdt.to_date
    enddt = enddt.to_date

    events = Hash.new { |hash, key| hash[key] = [] }

    # User holidays
    if @users_holidays && @users_holidays.has_key?(user.id)
      @users_holidays[user.id].each do |date, holidays|
        holidays.each do |holiday|
          events[date] << { name: holiday.name, type: 'easy_holiday_event' }
        end
      end
    end

    # Group holidays
    if @groups_holidays && @groups_holidays.has_key?(user.id)
      @groups_holidays[user.id].each do |date, holiday_events|
        holiday_events.each do |holiday_event|
          events[date] << holiday_event
        end
      end
    end

    # Meetings
    if @users_meetings && @users_meetings.has_key?(user.id)
      @users_meetings[user.id].each do |meeting|
        # start_date = User.current.time_to_date(meeting.start_time)
        # end_date = User.current.time_to_date(meeting.end_time)

        start_date = User.current.user_time_in_zone(meeting.start_time).to_date
        end_date = User.current.user_time_in_zone(meeting.end_time).to_date

        multiple_day_meeting = (start_date != end_date)

        start_date.upto(end_date) do |date|
          hours =
            if meeting.easy_resource_dont_allocate?
              0
            elsif multiple_day_meeting || meeting.all_day?
              EasyGanttResource.hours_on_week(user.id).fetch(date.cwday-1, 0)
            else
              meeting.duration_hours
            end

          events[date] << {
            name: meeting.name,
            hours: hours,
            type: 'meeting',
            dont_allocate: meeting.easy_resource_dont_allocate?,
          }
        end
      end
    end

    # Non working attendances
    if @users_attendances && @users_attendances.has_key?(user.id)
      @users_attendances[user.id].each do |attendance|
        date = User.current.time_to_date(attendance.arrival)
        events[date] << {
          name: attendance.easy_attendance_activity.name,
          hours: attendance.spent_time.to_f,
          type: 'nonworking_attendance'
        }
      end
    end

    if @waiting_users_attendances && @waiting_users_attendances.has_key?(user.id)
      @waiting_users_attendances[user.id].each do |attendance|
        date = User.current.time_to_date(attendance.arrival)
        events[date] << {
          name: "#{attendance.easy_attendance_activity.name} (#{attendance.attendance_status})",
          hours: attendance.spent_time.to_f,
          type: 'unapproved_nonworking_attendance'
        }
      end
    end

    # Non working group attendances
    if @users_groups_attendances && @users_groups_attendances.has_key?(user.id)
      @users_groups_attendances[user.id].each do |date, group_events|
        group_events.each do |group_event|
          events[date] << group_event
        end
      end
    end

    if @waiting_users_groups_attendances && @waiting_users_groups_attendances.has_key?(user.id)
      @waiting_users_groups_attendances[user.id].each do |date, group_events|
        group_events.each do |group_event|
          events[date] << group_event
        end
      end
    end

    events
  end

  def api_render_projects(api, projects)
    api.array :projects do
      projects.each do |project|
        api_render_project(api, project)
      end
    end
  end

  def api_render_project(api, project)
    api.project do
      api.id project.id
      api.name project.name

      if @projects_members
        api.members @projects_members[project.id]
      else
        api.members project.assignable_users.reorder(nil).pluck(:id)
      end

      api.allocator EasySetting.value(:easy_gantt_resources_default_allocator, project)
    end
  end

  def api_render_users(api, users)
    api.array :users do
      users.each do |user|
        api.user do
          api.id user.id
          api.name user.name
          api.week_hours EasyGanttResource.hours_on_week(user)
          api.estimated_ratio EasyGanttResource.estimated_ratio(user)
          api.resources_sums @resources_sums[user.id]
          api.events build_user_events_attributes(user, @period[:from], @period[:to])
          api.avatar avatar(user, size: 24, no_link: true)
          api.is_group user.is_a?(Group)

          if @users_groups && @users_groups.has_key?(user.id)
            if user.is_a?(Group)
              api.user_ids @users_groups[user.id]
            else
              api.group_ids @users_groups[user.id]
            end
          end
        end
      end
    end
  end

  def api_render_reservations(api, reservations)
    api.array :reservations do
      reservations.each do |reservation|
        api.reservation do
          api.id reservation.id
          api.name reservation.name
          api.allocator reservation.allocator
          api.start_date reservation.start_date
          api.due_date reservation.due_date
          api.assigned_to_id reservation.assigned_to_id
          api.estimated_hours reservation.estimated_hours
          api.project_id reservation.project_id
          api.description reservation.description

          api.array :resources do
            reservation.resources.each do |resource|
              api.resource do
                api.date resource.date
                api.hours resource.hours
              end
            end
          end
        end
      end
    end
  end

end
