class EasyGanttResourcesController < EasyGanttController
  accept_api_auth :project_data, :global_data, :users_sums, :projects_sums, :bulk_update_or_create, :allocated_issues, :user_calendar_settings

  before_action :build_custom_issues_resources, only: [:bulk_update_or_create]
  before_action :check_rest_api_enabled, only: [:index, :bulk_update_or_create]

  before_action :require_admin, only: [:user_calendar_settings]
  before_action :authorize, if: proc { @project.present? }, except: [:user_calendar_settings]
  before_action :authorize_global, if: proc { @project.nil? }, except: [:user_calendar_settings]

  def index
    if @project.nil? && !User.current.allowed_to_globally?(:view_global_easy_gantt_resources)
      return render_403
    end

    if @project && !User.current.allowed_to?(:view_easy_gantt_resources, @project)
      return render_403
    end

    respond_to do |format|
      format.html {
        if project_loading?
          render_404
        else
          retrieve_resource_query
        end
      }
    end
  end

  # Only json format is allowed (see routes)
  def project_data
    @period = period_from_params || default_period

    load_assignable_users
    load_users_events

    user_conditions = "assigned_to_id IS NULL"
    if @users.any?
      users_in = @users.map(&:id).join(',')
      user_conditions = "#{user_conditions} OR assigned_to_id IN (#{users_in})"
    end

    if params[:variant] != 'onlyReservation'
      @issues = Issue.select(:id, :project_id, :assigned_to_id).
                      preload(project: [:enabled_modules, members: :roles]).
                      preload(:custom_resource_allocator).
                      where(id: Array(params[:issue_ids])).
                      where(user_conditions).to_a
    end
    @issues ||= []

    if EasySetting.value(:easy_gantt_resources_reservation_enabled) && params[:variant] != 'onlyTask'
        @reservations = EasyGanttReservation.joins(:assigned_to).
                                             preload(:resources).
                                             where(user_conditions).to_a
    end

    Issue.load_visible_spent_hours(@issues)

    load_users_sums
    load_issues_resources
    load_issues_projects
    load_projects_members
    load_users_groups
  end

  # Only json format is allowed (see routes)
  def global_data
    retrieve_resource_query
    @period = @query.period
    # Load users issues
    if user_opening?
      preloads = [:custom_resource_allocator, { project: [:enabled_modules, members: :roles] }, :status]

      if EasySetting.value(:easy_gantt_resources_show_task_soonest_start)
        preloads << :parent
        preloads << { relations_to: :issue_from }
      end

      if EasySetting.value(:easy_gantt_resources_show_task_latest_due)
        preloads << :parent
        preloads << { relations_from: :issue_to }
      end

      preloads.uniq!

      @issues = @query.entities(preload: preloads,
                                order: 'issues.lft').to_a
      unless @query.has_column?(:spent_hours)
        Issue.load_visible_spent_hours(@issues)
      end

      if EasySetting.value(:easy_gantt_resources_reservation_enabled)
        @reservations = EasyGanttReservation.joins(:assigned_to).
                                             preload(:resources).
                                             where(assigned_to_id: params[:assigned_to_id]).to_a
      end

      load_issues_resources
      load_issues_versions
      load_issues_projects
      load_reservations_projects
      load_projects_members

    # Load just users
    else
      @users = @query.users
      load_users_groups
      load_users_events
      load_users_sums
    end
  end

  # == Parameters:
  # project_id:: (optional)
  # user_ids:: array of users ids
  # variant: allocations variant
  # resources_start_date::
  # resources_end_date::
  #
  def users_sums
    @period = period_from_params || default_period

    user_ids = Array(params[:user_ids])
    user_ids << nil if user_ids.delete('unassigned')

    except_issue_ids = Array(params[:except_issue_ids])
    except_reservation_ids = Array(params[:except_reservation_ids])

    case params[:variant]
    when 'planned'
      @resources_sums = Principal.easy_resources_planned_sums(user_ids, @period[:from], @period[:to], except_issue_ids: except_issue_ids)
    when 'onlyTask'
      @resources_sums = Principal.easy_resources_sums(user_ids, @period[:from], @period[:to],
                                                      except_issue_ids: except_issue_ids, include_reservations: false)
    when 'allData'
      @resources_sums = Principal.easy_resources_sums(user_ids, @period[:from], @period[:to],
                                                      except_issue_ids: except_issue_ids,
                                                      except_reservation_ids: except_reservation_ids)
    when 'onlyReservation'
      allocations = EasyGanttReservationResource.joins(:reservation)
                                                .where(easy_gantt_reservations: { assigned_to_id: user_ids })
                                                .where(date: @period[:from]..@period[:to])
                                                .where.not(easy_gantt_reservations: { id: except_reservation_ids })
                                                .group('easy_gantt_reservations.assigned_to_id',
                                                       'easy_gantt_reservation_resources.date')
                                                .pluck('easy_gantt_reservations.assigned_to_id',
                                                       'easy_gantt_reservation_resources.date',
                                                       'SUM(easy_gantt_reservation_resources.hours)')
      @resources_sums = Hash.new { |hash1, key1|
        hash1[key1] = {}
      }
      allocations.each do |user_id, date, hours|
        @resources_sums[user_id][date] = hours
      end

    else
      render_api_errors 'Wrong variant'
      return
    end
    # frontEnd needs to know all users to redraw
    user_ids.each do |user_id|
      @resources_sums[user_id.to_i] ||= {}
    end
  end

  # == Parameters:
  # project_ids::
  # resources_start_date::
  # resources_end_date::
  #
  # TODO: Unite sums methods
  #
  def projects_sums
    @period = period_from_params || default_period

    i_table = Issue.table_name
    project_ids = Array(params[:project_ids])

    @resources_sums = Hash.new { |hash, key| hash[key] = {} }

    scope = EasyGanttResource.joins(:issue).
                              where("#{i_table}.project_id IN (?)", project_ids).
                              where('hours > 0').
                              between_dates(@period[:from], @period[:to])

    scope = scope.group("#{i_table}.project_id", :date).sum(:hours)
    scope.each do |(project_id, date), hours|
      @resources_sums[project_id][date] = hours
    end
  end

  def allocated_issues
    from = params[:from].to_date rescue Date.today
    to = params[:to].to_date rescue Date.today

    user_ids = [params[:user_id].to_i]
    if Group.exists?(id: user_ids)
      user_ids.concat Principal.from('groups_users').
                                where(groups_users: { group_id: user_ids }).
                                pluck(:user_id)
    end

    @issues_data = collect_issues_data(from, to, user_ids, params[:except_issue_ids])
    @reservations_data = collect_reservations_data(from, to, user_ids, params[:except_reservation_ids])
  end

  def bulk_update_or_create
    # Save hours
    _, unsaved_resources = EasyGanttResource.save_allocation_from_params(@custom_issues_resources)
    errors = unsaved_resources.values

    # Save custom allocators
    allocators = params.to_unsafe_hash.with_indifferent_access[:allocators]
    if allocators.is_a?(Array)
      allocators = allocators.map{|a| [a['issue_id'].to_i, a['allocator']]}
      allocators = Hash[allocators]

      issues = Issue.preload(:custom_resource_allocator).where(id: allocators.keys)
      issues.each do |issue|
        new_allocator = allocators[issue.id]
        old_allocator = issue.resource_allocator

        if new_allocator == old_allocator
          issue.custom_resource_allocator.try(:delete)
        else
          issue.create_custom_resource_allocator(allocator: new_allocator)
        end
      end
    end

    # Recalculate for "original hours"
    # Allocatour could change so its better than call `.reload`
    issues = Issue.preload(:status).where(id: @custom_issues_resources.keys)
    issues.each do |issue|
      next unless issue.allocable?
      allocator = EasyGanttResources::IssueAllocator.get(issue)
      allocator.recalculate_original_hours!
    end

    respond_to do |format|
      format.api do
        if errors.flatten.blank?
          render_api_ok
        else
          render_api_errors errors
        end
      end
    end
  end

  def user_calendar_settings
    result = []

    users = User.preload(:working_time_calendar).where(id: params[:user_ids])
    users.each do |user|
      result << {
        user_id: user.id,
        default_working_hours: user.default_working_hours,
        non_working_week_days: EasyGantt.non_working_week_days(user)
      }
    end

    respond_to do |format|
      format.json {
        render json: result
      }
    end
  end

  private

    def collect_reservations_data(from, to, user_ids, except_ids)
      i_table = EasyGanttReservation.table_name
      r_table = EasyGanttReservationResource.table_name
      p_table = Project.table_name

      resources = EasyGanttReservationResource.left_outer_joins(reservation: :project).
                                               where(easy_gantt_reservations: { assigned_to_id: user_ids } ).
                                               where.not(easy_gantt_reservation_id: Array(except_ids)).
                                               between_dates(from, to)

      resources.group("#{i_table}.id, #{i_table}.name, #{p_table}.id").pluck(Arel.sql("#{i_table}.id, #{i_table}.name, SUM(#{r_table}.hours), #{p_table}.id, #{p_table}.name"))
    end

    def collect_issues_data(from, to, user_ids, except_ids)
      i_table = Issue.table_name
      r_table = EasyGanttResource.table_name
      p_table = Project.table_name

      resources = EasyGanttResource.non_templates.active_and_planned.
                                    joins(issue: :project).
                                    where(user_id: user_ids).
                                    where('hours > 0').
                                    where.not(issue_id: Array(except_ids)).
                                    between_dates(from, to)

      resources.group("#{i_table}.id, #{i_table}.subject, #{p_table}.id").pluck(Arel.sql("#{i_table}.id, #{i_table}.subject, SUM(#{r_table}.hours), #{p_table}.id, #{p_table}.name"))
    end

    def project_loading?
      @project.present?
    end

    def global_loading?
      @project.nil? && !user_opening?
    end

    def user_opening?
      @project.nil? && params[:assigned_to_id].present?
    end

    def default_period
      {
        from: EasyGanttResources.default_resources_start_date,
        to: EasyGanttResources.default_resources_end_date
      }
    end

    def period_from_params
      return if params[:resources_start_date].blank? || params[:resources_end_date].blank?

      {
        from: params[:resources_start_date].to_date,
        to: params[:resources_end_date].to_date
      }
    rescue ArgumentError
    end

    def query_class
      easy_extensions? ? EasyResourceEasyQuery : EasyResourceQuery
    end

    def retrieve_resource_query
      retrieve_query
      if params[:assigned_to_id].present?
        @query.assigned_to = params[:assigned_to_id]
      end
      @query.ensure_period_filter
    end

    def load_issues_resources
      @issues_resources = Hash.new do |hash, key|
        hash[key] = Hash.new do |hash, key|
          hash[key] = { hours: 0, custom: false }
        end
      end
      resources = EasyGanttResource.non_templates.where(issue_id: @issues.map(&:id))
      resources.each do |resource|
        @issues_resources[resource.issue_id][resource.date.to_s][:hours] += resource.hours
        @issues_resources[resource.issue_id][resource.date.to_s][:custom] ||= resource.custom?
      end
    end

    def load_issues_projects
      @projects = @issues.map(&:project).uniq
    end

    def load_reservations_projects
      return unless @reservations

      @projects ||= []
      @projects = @projects | @reservations.map(&:project).compact.uniq
    end

    def load_issues_versions
      version_ids = @issues.map(&:fixed_version_id).uniq
      @issues_versions = Version.where(id: version_ids)
    end

    def load_users_sums
      includes = {}
      case params[:variant]
      when "onlyReservation"
        includes[:include_issues] = false
      when "onlyTask"
        includes[:include_reservations] = false
      end

      @resources_sums = Principal.easy_resources_sums(@users, @period[:from], @period[:to], **includes)
    end

    def load_assignable_users
      types = ['User']
      types << 'Group' if Setting.issue_group_assignment?

      if EasyGantt.easy_extensions?
        preloads = (Setting.gravatar_enabled? ? :email_address : :easy_avatar)
      else
        # On redmine you cannot preload email_address to Group
        # preloads = (Setting.gravatar_enabled? ? :email_address : nil)
      end

      @users = Principal.distinct.active.visible.sorted.
                         joins(members: :roles).
                         preload(preloads).
                         where(type: types, members: { project_id: Array(params[:project_ids]) },
                                            roles: { assignable: true }).
                         to_a
    end

    def load_users_groups
      @users_groups = Hash.new { |hash, key| hash[key] = [] }

      group_ids = @users.map { |user|
        user.id if user.is_a?(Group)
      }
      group_ids.compact!
      group_ids.uniq!

      if group_ids.empty?
        return
      end

      groups_users = Principal.from('groups_users').
                               where(groups_users: { group_id: group_ids }).
                               pluck(:user_id, :group_id)
      groups_users.each do |user_id, group_id|
        @users_groups[user_id] << group_id
        @users_groups[group_id] << user_id
      end
    end

    def load_users_events
      if EasyGantt.easy_extensions?
        load_users_holidays
        load_groups_holidays
      end
      if EasyGantt.easy_calendar?
        load_users_meetings
      end
      if EasyGantt.easy_attendances?
        load_users_attendances
        load_groups_attendances
      end
    end

    def load_users_holidays
      startdt = @period[:from]
      enddt = @period[:to]

      users = @users.select{|u| u.is_a?(User) }
      @users_holidays = EasyGanttResources.users_holidays(users, startdt, enddt)
    end

    def load_groups_holidays
      return unless EasySetting.value(:easy_gantt_resources_groups_holidays_enabled)

      startdt = @period[:from]
      enddt = @period[:to]

      groups = @users.select{|u| u.is_a?(Group) }
      groups = groups.map{|g| [g.id, g.users.ids] }.to_h

      user_ids = groups.values.flatten
      user_ids.uniq!

      user_names = User.where(id: user_ids).map{|u| [u.id, u.name] }.to_h

      @groups_holidays = Hash.new { |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = [] }
      }

      users_holidays = EasyGanttResources.users_holidays(user_ids, startdt, enddt)

      groups.each do |group_id, user_ids|
        group_hours_on_week = EasyGanttResource.hours_on_week(group_id)
        capacity_per_user = 1.0 / groups[group_id].size

        user_ids.each do |user_id|
          next unless users_holidays.has_key?(user_id)

          users_holidays[user_id].each do |date, holidays|
            holidays.each do |holiday|

              @groups_holidays[group_id][date] << {
                name: "(#{user_names[user_id]}) #{holiday.name}",
                type: 'easy_holiday_event',
                hours: (group_hours_on_week[date.cwday-1] * capacity_per_user)
              }

              # For now, take only first holiday
              break
            end
          end
        end
      end
    end

    def load_users_meetings
      startdt = @period[:from]
      enddt = @period[:to]

      meetings = EasyMeeting.left_outer_joins(:easy_invitations).where(start_time: startdt..enddt, end_time: startdt..enddt).
        where(easy_invitations: {user_id: @users, accepted: [true, nil]}).
        select("easy_invitations.user_id as user_id, easy_meetings.id, name, start_time, end_time, all_day, easy_resource_dont_allocate")

      @users_meetings = meetings.group_by(&:user_id)
    end

    def users_attendances_data(startdt, enddt, users, status)
      EasyAttendance.non_working.
                     between(startdt, enddt).
                     preload(:easy_attendance_activity).
                     where(user_id: users,
                           approval_status: status).
                     group_by(&:user_id)
    end

    def load_users_attendances
      startdt = @period[:from]
      enddt = @period[:to]

      @users_attendances = users_attendances_data(startdt, enddt, @users, EasyAttendance::APPROVAL_APPROVED)
      @waiting_users_attendances = users_attendances_data(startdt, enddt, @users, EasyAttendance::APPROVAL_WAITING)
    end

    def groups_attendances_data(startdt:, enddt:, user_groups:, groups:, users:, status:, result_type:)
      result = Hash.new { |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = [] }
      }

      all_attendances = EasyAttendance.non_working.
                                       between(startdt, enddt).
                                       preload(:easy_attendance_activity, :user).
                                       where(user_id: users,
                                             approval_status: status).
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

            name = attendance.easy_attendance_activity.name
            name = "#{name} (#{attendance.attendance_status})" if !attendance.approved?

            # User work this part for tasks on group
            result[group_id][date] << {
              name: name,
              hours: (group_hours_on_week[date.cwday-1] * user_not_worked_for_group_on),
              original_hours: attendance.spent_time.to_f,
              original_user_id: attendance.user_id,
              original_user_name: attendance.user.name,
              type: result_type
            }
          end
        end
      end

      result
    end

    def load_groups_attendances
      startdt = @period[:from]
      enddt = @period[:to]

      groups = @users.select{|u| u.is_a?(Group) }
      groups = groups.map{|g| [g.id, g.users.ids] }.to_h

      user_ids = groups.values.flatten
      user_ids.uniq!

      user_groups = Hash.new { |hash, key| hash[key] = [] }
      groups.each do |group_id, user_ids|
        user_ids.each do |user_id|
          user_groups[user_id] << group_id
        end
      end

      @users_groups_attendances = groups_attendances_data(
        startdt: startdt,
        enddt: enddt,
        user_groups: user_groups,
        groups: groups,
        users: user_ids,
        status: EasyAttendance::APPROVAL_APPROVED,
        result_type: 'nonworking_attendance')

      @waiting_users_groups_attendances = groups_attendances_data(
        startdt: startdt,
        enddt: enddt,
        user_groups: user_groups,
        groups: groups,
        users: user_ids,
        status: EasyAttendance::APPROVAL_WAITING,
        result_type: 'unapproved_nonworking_attendance')
    end

    def load_projects_members
      types = ['User']
      types << 'Group' if Setting.issue_group_assignment?

      @projects_members = Hash.new { |hash, key| hash[key] = [] }

      members = Member.joins(:principal, :roles).
                       where(project_id: @projects,
                             users: { status: Principal::STATUS_ACTIVE, type: types },
                             roles: { assignable: true }).
                       pluck(:project_id, :user_id)
      members.each do |project_id, user_id|
        @projects_members[project_id] << user_id
      end
    end

    def build_custom_issues_resources
      unless params[:resources].is_a?(Array)
        return render_error status: 422, message: l(:error_bad_data)
      end

      issue_ids = params[:resources].map{ |r| r['issue_id'] }.uniq
      issues = Issue.preload(:status).where(id: issue_ids).map{ |i| [i.id, i] }
      issues = Hash[issues]

      data = {}
      params[:resources].each do |resource|
        issue = issues[resource['issue_id'].to_i]
        next if issue.nil?

        data[issue] ||= []
        data[issue] << resource
      end

      @custom_issues_resources = data
    end

end
