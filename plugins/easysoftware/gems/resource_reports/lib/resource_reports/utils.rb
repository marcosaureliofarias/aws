# frozen_string_literal: true

module ResourceReports
  module Utils
    extend self

    # Group holidays
    # Since groups have no holidays - it's calculated by group's users
    # see {EasyGanttResources::IssueAllocator#group_holidays}
    def groups_holidays(groups, from:, to:)
      return if !EasySetting.value(:easy_gantt_resources_groups_holidays_enabled)

      groups = groups.select{|u| u.is_a?(Group) }
      groups = groups.map{|g| [g.id, g.users.ids] }.to_h

      user_ids = groups.values.flatten
      user_ids.uniq!

      users_holidays = EasyGanttResources.users_holidays(user_ids, from, to)

      groups.each do |group_id, user_ids|
        group_hours_on_week = EasyGanttResource.hours_on_week(group_id)
        capacity_per_user = 1.0 / user_ids.size

        user_ids.each do |user_id|
          next unless users_holidays.has_key?(user_id)

          users_holidays[user_id].each do |date, holidays|
            holidays.each do |holiday|
              hours = (group_hours_on_week[date.cwday-1] * capacity_per_user)
              yield group_id, user_id, holiday, date, hours
            end
          end
        end
      end
    end

    def users_holidays(users, from:, to:)
      users = users.select{|u| u.is_a?(User) }
      user_ids = users.select(&:id)

      users_holidays = EasyGanttResources.users_holidays(user_ids, from, to)

      users.each do |user|
        next if !users_holidays.has_key?(user.id)

        user_capacity = EasyGanttResource.hours_on_week(user)

        users_holidays[user.id].each do |date, holidays|
          holidays.each do |holiday|
            hours = user_capacity[date.cwday-1]
            yield user.id, holiday, date, hours
          end
        end
      end
    end

    def groups_non_working_attendances(groups, from:, to:)
      groups = groups.select{|u| u.is_a?(Group) }
      groups = groups.map{|g| [g.id, g.users.ids] }.to_h

      user_ids = groups.values.flatten
      user_ids.uniq!

      user_groups = Hash.new { |hash, key| hash[key] = [] }
      groups.each do |group_id, user_ids|
        user_ids.each do |user_id|
          user_groups[user_id] << group_id
        end
      end

      all_attendances = EasyAttendance.non_working.
                                       between(from, to).
                                       preload(:easy_attendance_activity, :user).
                                       where(user_id: user_ids,
                                             approval_status: EasyAttendance::APPROVAL_APPROVED).
                                       group_by(&:user_id)

      all_attendances.each do |user_id, attendances|
        # Max hours allocated on user
        # TODO: preload user
        user_hours_on_week = EasyGanttResource.hours_on_week(user_id)

        group_ids = user_groups[user_id]
        group_ids.each do |group_id|

          group_hours_on_week = EasyGanttResource.hours_on_week(group_id)

          # Capacity on group
          capacity_per_user = 1.0 / groups[group_id].size

          attendances.each do |attendance|
            date = User.current.time_to_date(attendance.arrival)

            # User not work that day on N %
            user_not_worked_for_self_on = [attendance.spent_time.to_f / user_hours_on_week[date.cwday-1], 1].min

            # So user not work that day for group on N %
            user_not_worked_for_group_on = capacity_per_user * user_not_worked_for_self_on

            # User work this part for tasks on group
            hours = (group_hours_on_week[date.cwday-1] * user_not_worked_for_group_on)

            yield group_id, user_id, attendance, date, hours
          end
        end
      end
    end

    def users_non_working_attendances(users, from:, to:)
      users = users.select{|u| u.is_a?(User) }

      attendances = EasyAttendance.non_working.
                                   between(from, to).
                                   preload(:easy_attendance_activity, :time_entry).
                                   where(user_id: users,
                                         approval_status: EasyAttendance::APPROVAL_APPROVED)

      attendances.each do |attendance|
        date = User.current.time_to_date(attendance.arrival)
        hours = attendance.spent_time.to_f

        yield attendance.user_id, attendance, date, hours
      end
    end

  end
end
