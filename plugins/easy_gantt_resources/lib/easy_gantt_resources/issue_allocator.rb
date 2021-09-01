module EasyGanttResources
  ##
  # Base class
  # Should not be allocated
  #
  class IssueAllocator

    Allocation = Struct.new(:date, :start, :hours, :custom)

    MAX_ALLOCATIONS = 365

    attr_reader :issue
    attr_reader :range
    attr_reader :allocations

    # Future prefix in allocator is just "flag" which says allocations must
    # be in future. It is not meant as complete separate allocator.
    def self.get(issue)
      start = issue.start_date
      due = issue.due_date

      resource_allocator = issue.resource_allocator
      is_future = resource_allocator.start_with?('future_')
      type = resource_allocator.sub('future_', '')
      today = Date.today

      if start.present? && due.present?
        #          [TODAY]
        #   |---|                       due..due
        #      |-------------|          today..due
        #                   |---|       start..due
        if is_future
          start = if due < today
                    due
                  elsif start > today
                    start
                  else
                    today
                  end
        end

        case type
        when 'evenly'
          range = due.downto(start)
        when 'from_start'
          range = start.upto(due)
        when 'from_end'
          range = due.downto(start)
        when 'random'
          range = start.upto(due)
        end

      elsif start.present?
        #          [TODAY]
        #   |--------------------       today..
        #                   |----       start..
        if is_future && start < today
          start = today
        end
        type = 'from_start'
        range = start.upto(start+MAX_ALLOCATIONS.days)

      elsif due.present?
        #          [TODAY]
        #   ----|                       due..due
        #   --------------------|       today..due
        range = if is_future
                  if due < today
                    due.downto(due)
                  else
                    due.downto(today)
                  end
                else
                  due.downto(due-MAX_ALLOCATIONS.days)
                end
        type = 'from_end'

      else
        raise 'Start or due date is required'
      end

      case type
      when 'evenly'
        EvenlyAllocator.new(issue, range)
      when 'random'
        RandomAllocator.new(issue, range)
      else
        RangeAllocator.new(issue, range)
      end
    end

    def self.reallocate!
      Rails.logger.tagged('IssueAllocationsRecalculation') do
        Rails.logger.info 'Deleting allocations'
        EasyGanttResource.delete_all

        allowed_statuses = [Project::STATUS_ACTIVE]
        if Project.const_defined?(:STATUS_PLANNED)
          allowed_statuses << Project::STATUS_PLANNED
        end

        issues = Issue.open.includes(:project, :status, :assigned_to).
            where(projects: { status: allowed_statuses }).
            where.not(estimated_hours: nil)

        Rails.logger.info 'Reallocating issues'
        issues.find_each(batch_size: 1000).with_index do |issue, index|
          issue.reallocate_resources
          Rails.logger.info "... #{index} issues reallocated\r" if index % 50 == 0
        end
        Rails.logger.info "... DONE"
      end
    end

    def initialize(issue, range)
      @issue = issue
      @range = range.to_a

      # By resource settings
      @max_hours_on_week = EasyGanttResource.hours_on_week(issue.assigned_to)

      # New allocation
      @allocations = []

      # Only custom allocation should remain
      custom_resources = issue.easy_gantt_resources.where(date: range.min..range.max, custom: true).order(:date)
      custom_resources.each do |resource|
        allocations << Allocation.new(resource.date, resource.start, resource.hours, resource.custom)
      end
    end

    # Reset allocation from previous run and
    # calculate how many hours should be allocated
    def prepare_for_allocation(with_spent_time: true)
      estimated_hours = issue.estimated_hours.to_f * EasyGanttResource.estimated_ratio(issue.assigned_to_id)

      if with_spent_time
        remaining_hours = estimated_hours - issue.spent_hours.to_f
      else
        remaining_hours = estimated_hours
      end

      custom_hours = allocations.select(&:custom).sum(&:hours)

      # Reset custom allocations only if there more custom hours than estimate
      allocations.each do |allocation|
        if allocation.custom
          if custom_hours > remaining_hours
            custom_hours -= allocation.hours
            allocation.hours = 0
            allocation.custom = false
          end
        else
          allocation.hours = 0
        end
      end

      @hours_to_allocate = [0, (remaining_hours - custom_hours)].max
    end

    # Recalculate hours and origin_hours
    # All allocations are replaced for new one
    # Its faster than run multiple UPDATE SQL
    def recalculate!
      prepare_for_allocation(with_spent_time: true)
      allocate_resources
      regular_hours_allocations = allocations.deep_dup

      prepare_for_allocation(with_spent_time: false)
      allocate_resources
      original_hours_allocations = allocations.deep_dup

      resources = []
      allocations_to_gantt_resources(resources, regular_hours_allocations, 'hours')
      allocations_to_gantt_resources(resources, original_hours_allocations, 'original_hours')

      resources.keep_if do |resource|
        (resource.hours && resource.hours > 0) ||
        (resource.original_hours && resource.original_hours > 0)
      end

      EasyGanttResource.transaction do
        EasyGanttResource.where(issue_id: issue.id).delete_all
        EasyGanttResource.import(resources)

        # This is because of mass import above
        # Resources have changed but an issue object still cache old resources
        # It could be a problem during saving -> resources look like invalid
        issue.easy_gantt_resources.reload
      end
    end

    # Currently front-end is sending only regular hours so
    # original must be recalculated by server
    def recalculate_original_hours!
      prepare_for_allocation(with_spent_time: false)
      allocate_resources
      save_allocations_by_one(allocations, 'original_hours')
    end

    def allocations_to_gantt_resources(resources, allocations, column)
      resources.each do |resource|
        resource.write_attribute(column, 0)
      end

      allocations.each do |allocation|
        resource = resources.find {|r| r.date == allocation.date && r.start == allocation.start }

        if resource.nil?
          resource = issue.easy_gantt_resources.build(
            date: allocation.date,
            start: allocation.start,
            hours: 0,
            original_hours: 0,
          )
          resources << resource
        end

        resource.user_id = issue.assigned_to_id
        resource.custom = allocation.custom
        resource.write_attribute(column, allocation.hours)
      end

      resources
    end

    def save_allocations_by_one(allocations, column)
      return unless issue.persisted?

      resources = EasyGanttResource.where(issue_id: issue.id).to_a
      allocations_to_gantt_resources(resources, allocations, column)

      EasyGanttResource.transaction do
        resources.each do |resource|

          if resource.changed? && !resource.save
            issue.errors.add(:easy_gantt_resources, resource.errors.full_messages.join(', '))
            raise ActiveRecord::Rollback
          end

        end
      end
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('Deadlock found')
        # It happens some times
        # For unknow reasons
      else
        raise
      end
    end

    def update_allocations(date, hours)
      allocation = @allocations.find{|res| res.date == date }

      if allocation.nil?
        #                          :date, :start, :hours, :custom
        allocation = Allocation.new(date, nil, 0, false)
        @allocations << allocation
      end

      allocation.hours += hours
      allocation
    end

    def hours_on(date)
      @max_hours_on_week[date.cwday - 1]
    end

    def holiday?(date)
      wc = issue.assigned_to.try(:current_working_time_calendar)
      return false if wc.blank?

      wc.holiday?(date)
    end

    def user_holiday?(date)
      issue.assigned_to.is_a?(User) && holiday?(date)
    end

    def group_holidays
      return @group_holidays if @group_holidays

      @group_holidays = Hash.new(0)

      if !EasyGantt.easy_extensions? || !issue.assigned_to.is_a?(Group) || !EasySetting.value(:easy_gantt_resources_groups_holidays_enabled)
        return @group_holidays
      end

      # User1 allocate max 8h
      # User2 allocate max 5h
      #
      # Group (User1, User2) allocate max 10h
      #
      # group_size = 2
      # capacity_per_user = 0.5
      #
      # User1 have holiday
      #   hours - 5
      #
      # User2 have holiday
      #   hours - 5
      #
      # User1 have holiday
      # User2 have holiday
      #   hours - 10
      #

      group_size = issue.assigned_to.users.count
      capacity_per_user = 1.0 / group_size

      users_holidays = EasyGanttResources.users_holidays(issue.assigned_to.users, range.min, range.max)
      users_holidays.each do |user_id, user_data|
        user_hours_on_week = EasyGanttResource.hours_on_week(user_id)

        user_data.each do |date, holidays|
          hours_on_day = user_hours_on_week[date.cwday-1]

          holidays.each do |holiday|
            @group_holidays[date] += (hours_on(date) * capacity_per_user)

            # If there are more holidays (in one day)
            # Holiday for user on one day should not be calculated twice
            break
          end
        end
      end

      @group_holidays
    end

    def custom_allocation?(date)
      # `.any` is because of scheduler
      # you can have more allocations on the same day (all should be only custom)
      allocations.any? {|a| a.date == date && a.custom }
    end

    def allocable_hours_on(date)
      if user_holiday?(date)
        return 0
      end

      hours = hours_on(date)
      hours -= nonworking_attendaces[date]
      hours -= group_holidays[date]
      [0, hours].max
    end

    def nonworking_attendaces
      return @nonworking_attendaces if @nonworking_attendaces

      @nonworking_attendaces = Hash.new(0)

      unless EasyGantt.easy_attendances?
        return @nonworking_attendaces
      end

      case issue.assigned_to
      when User
        attendaces = issue.assigned_to.easy_attendances.non_working.between(range.min, range.max).where(approval_status: EasyAttendance::APPROVAL_APPROVED)
        attendaces.each do |attendace|
          @nonworking_attendaces[attendace.arrival.to_date] += attendace.spent_time.to_f
        end

      when Group
        # User1 allocate max 8h
        # User2 allocate max 5h
        #
        # Group (User1, User2) allocate max 10h
        #
        # User2 have vacation 3h
        #
        #   group_size = 2
        #   capacity_per_user = 0.5
        #
        #   user_hours_per_day = 5
        #   user_not_worked_for_self_on = 0.6
        #   user_not_worked_for_group_on = 0.3
        #
        #   nonworking_attendaces[] = 3
        #
        # TODO: Iterate per user group

        group_size = issue.assigned_to.users.count
        capacity_per_user = 1.0 / group_size

        attendaces = EasyAttendance.non_working.between(range.min, range.max).where(user_id: issue.assigned_to.users.ids, approval_status: EasyAttendance::APPROVAL_APPROVED)
        attendaces.each do |attendace|
          date = attendace.arrival.to_date

          # Max hours allocated on user
          # TODO: Preload user
          # TODO: Compute once
          user_hours_on_week = EasyGanttResource.hours_on_week(attendace.user_id)

          # User not work that day on N %
          user_not_worked_for_self_on = [attendace.spent_time.to_f / user_hours_on_week[date.cwday-1], 1].min

          # So user not work that day for group on N %
          user_not_worked_for_group_on = capacity_per_user * user_not_worked_for_self_on

          # User work this part for tasks on group
          @nonworking_attendaces[date] += hours_on(date) * user_not_worked_for_group_on
        end
      end

      @nonworking_attendaces
    end

    def inspect
      result  = %{#<#{self.class.name}:0x#{object_id}\n}
      result << %{  Issue (##{issue.id}): #{issue.subject}\n}
      result << %{  Range: #{range.min} - #{range.max}\n}
      result << %{  Hours: #{@max_hours_on_week}\n}
      result << %{  Resources:}

      allocations.sort_by(&:date).each do |allocation|
        result << %{\n     date: #{allocation.date}, hours: #{allocation.hours}}
        result << %{ (custom)} if allocation.custom
      end
      result << %{>}
      result
    end

  end


  # ===========================================================================
  # EvenlyAllocator
  #
  class EvenlyAllocator < IssueAllocator

    def allocate_resources
      hours_to_allocate = @hours_to_allocate

      # Fallback for empty range
      first_day = range.first

      # Select only valid dates
      range.delete_if do |date|
        custom_allocation?(date) || holiday?(date) || hours_on(date) <= 0 || nonworking_attendaces[date] != 0
      end

      # There is no valid dates - for example all days are holidays
      if range.empty?
        @range = [first_day]
      end

      updated_allocations = []

      hour_per_day = hours_to_allocate.div(range.size)

      if EasySetting.value(:easy_gantt_resources_decimal_allocation)
        remainder_decrement_by = 0.5
      else
        remainder_decrement_by = 1
      end

      # Allocate evenly hours to every date (even zeros)
      range.each do |date|
        hours_to_allocate -= hour_per_day
        updated_allocations << update_allocations(date, hour_per_day)
      end

      # Estimate = 9h
      #
      # First round
      # |  1  |  1  |  1  |  1  |  1  | ~ 5h
      #
      #   Without a loop
      #   | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | ~ 7.5h
      #   | 1.5 | 1.5 | 1.5 | 1.5 |  3  | ~ 9h
      #
      #   With a loop
      #   | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | ~ 7.5h
      #   |  2  |  2  |  2  | 1.5 | 1.5 | ~ 9h
      #
      loop do
        break if hours_to_allocate < remainder_decrement_by

        # Now allocate remainders (remainder hours is always smaller than days count in range)
        updated_allocations.each do |allocation|
          allocation.hours += remainder_decrement_by
          hours_to_allocate -= remainder_decrement_by

          break if hours_to_allocate < remainder_decrement_by
        end
      end

      # There are still hours need to be allocated
      # For example all days are non working or there left decimal part of hours
      if hours_to_allocate > 0
        if updated_allocations.any?
          allocation = updated_allocations.max_by(&:date)
          allocation.hours += hours_to_allocate
        else
          # Issue is placed only to non-working days
          update_allocations(range.max, hours_to_allocate)
        end
      end
    end

  end

  # ===========================================================================
  # RangeAllocator
  #
  class RangeAllocator < IssueAllocator

    def allocate_resources
      hours_to_allocate = @hours_to_allocate

      updated_allocations = []
      range.each_with_index do |date, index|
        break if index > MAX_ALLOCATIONS
        break if hours_to_allocate <= 0
        next if custom_allocation?(date)

        hours = [allocable_hours_on(date), hours_to_allocate].min
        next if hours <= 0

        hours_to_allocate -= hours
        updated_allocations << update_allocations(date, hours)
      end

      # There are still hours need to be allocated
      if hours_to_allocate > 0
        if updated_allocations.any?
          allocation = updated_allocations.max_by(&:date)
          allocation.hours += hours_to_allocate
        else
          # Issue is placed only to non-working days
          update_allocations(range.max, hours_to_allocate)
        end
      end
    end

  end

  # ===========================================================================
  # RandomAllocator
  #
  class RandomAllocator < IssueAllocator

    HOURS_RANGE = 1..10

    def allocate_resources
      hours_to_allocate = @hours_to_allocate

      updated_allocations = []
      range.each_with_index do |date, index|
        break if index > MAX_ALLOCATIONS
        break if hours_to_allocate <= 0
        next if custom_allocation?(date)

        hours = [rand(HOURS_RANGE), hours_to_allocate].min
        next if hours <= 0

        hours_to_allocate -= hours
        updated_allocations << update_allocations(date, hours)
      end

      # There are still hours need to be allocated
      if hours_to_allocate > 0
        if updated_allocations.any?
          allocation = updated_allocations.max_by(&:date)
          allocation.hours += hours_to_allocate
        else
          # Issue is placed only to non-working days
          update_allocations(range.max, hours_to_allocate)
        end
      end
    end

  end

end
