class EasyAutoCompletesController < ApplicationController
  helper :issues
  include IssuesHelper

  before_action :set_self_only
  accept_api_auth :index

  def index
    action = params[:autocomplete_action].to_s.to_sym
    if self.respond_to?(action)
      __send__(action)
    else
      render_404
    end
  end

  def query_entities
    if (options = params[:autocomplete_options] && params[:autocomplete_options].permit!) && (entity = options.delete(:entity))
      begin
        entity_class     = entity.constantize
        easy_query       = entity.downcase.include?('easy') ? "#{entity}Query" : "Easy#{entity}Query"
        easy_query_class = easy_query.constantize
      rescue
      end
    end
    options ||= {}

    if entity_class.is_a?(Class) && easy_query_class.is_a?(Class)
      q                    = easy_query_class.new
      q.use_free_search    = true
      q.free_search_tokens = params[:term].to_s
      q.sort_criteria      = q.sort_criteria_init
      q_options            = { limit: EasySetting.value('easy_select_limit').to_i }.merge!(options)
      @entities            = q.entities(q_options).to_a
      @name_column         = :name if entity_class.method_defined?(:name)
    else
      @entities = []
    end
    @name_column ||= :to_s

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: { additional_select_options: options[:additional_select_options] } }
    end
  end

  def issues_with_parents
    @entities = get_issues_with_parents(params[:term], EasySetting.value('easy_select_limit').to_i)

    @name_column = :to_s
    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/entities_with_id', :formats => [:api], locals: { additional_select_options: false } }
    end
  end

  def issues_with_children
    @entities = issues_with_children_values(options: params_for_remote_autocomplete)

    @name_column = :to_s
    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/entities_with_id', :formats => [:api], locals: { additional_select_options: false } }
    end
  end

  def issue_autocomplete
    @entities = get_visible_issues(params[:term], EasySetting.value('easy_select_limit').to_i)

    @name_column = :to_s
    respond_to do |format|
      format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: { additional_select_options: false } }
    end
  end

  def root_issues
    @entities = get_root_issues(params[:term], EasySetting.value('easy_select_limit').to_i)

    @name_column = :to_s
    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/entities_with_id', :formats => [:api], locals: { additional_select_options: false } }
    end
  end

  def parent_issues
    project = Project.find(params[:project_id]) if params[:project_id].present?
    @issues = get_available_parent_issues(project, params[:term], EasySetting.value('easy_select_limit').to_i)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/parent_issues', :formats => [:api] }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def my_projects
    @projects = Project.search_results(params[:term], User.current, nil, titles_only: true, limit: EasySetting.value('easy_select_limit').to_i)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_url', :formats => [:api] }
    end
  end

  def visible_projects
    @projects = get_visible_projects(params[:term], EasySetting.value('easy_select_limit').to_i)

    @additional_options = []
    @additional_options << ["--- #{l(:label_in_modules)} ---", ''] if params[:include_system_options]&.include?('no_filter')

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/projects_with_id', locals: { additional_select_options: @additional_options }, formats: [:api]
      }
    end
  end

  def visible_active_projects
    @projects = get_visible_projects_scope(params[:term], EasySetting.value('easy_select_limit').to_i).active_and_planned.to_a

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api] }
    end
  end

  def visible_search_suggester_entities
    search_types = EasySetting.value('easy_search_suggester')['entity_types'].to_a & EasyExtensions::Suggester.available_search_types
    search_types.unshift 'proposer'

    limit = EasySetting.value('easy_select_limit').to_i
    term  = params[:term].to_s.strip
    open_projects = false

    case term
    when /\A(t|task|tasks):(.+)/
      search_types = ['issues']
      term         = $2.strip
    when /\A(p|project|projects):(.+)/
      search_types = ['projects']
      term         = $2.strip
    when /\A(po|project open|projects open):(.+)/
      search_types = ['projects']
      term         = $2.strip
      open_projects = true
    when /\A(u|user|users):(.+)/
      search_types = ['users']
      term         = $2.strip
    end

    @suggest_entities = EasyExtensions::Suggester.search(
        term,
        types: search_types,
        limit: limit,
        open_projects: open_projects
    )

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/entities_with_url', formats: [:api] }
    end
  end

  def project_templates
    @projects = get_template_projects(params[:term], EasySetting.value('easy_select_limit').to_i)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api] }
    end
  end

  def add_issue_projects
    @projects = get_visible_projects_with_permission(:add_issues, params[:term], EasySetting.value('easy_select_limit').to_i)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api] }
    end
  end

  def allowed_target_projects_on_move
    @projects = get_visible_projects_with_permission(:move_issues, params[:term], EasySetting.value('easy_select_limit').to_i)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api] }
    end
  end

  def allowed_issue_statuses
    @allowed_statuses = begin
      if @issue = Issue.find_by(id: params[:issue_id])
        @issue.new_statuses_allowed_to
      else
        @issue = Issue.new(project_id: params[:project_id])
        @issue.safe_attributes = params[:issue]&.except(:project_id) || {}
        @issue.new_statuses_allowed_to(User.current, true)
      end
    end
    json_statuses = @allowed_statuses.reduce([]) do |json_statuses, status|
      if !params[:term].present? || status.name.include?(params[:term])
        json_statuses << { text: status.name, value: status.id }
      end
      json_statuses
    end

    render json: json_statuses
  end

  def allowed_issue_trackers
    @allowed_trackers = begin
      if params[:issue_id]
        Issue.find_by(id: params[:issue_id]).try(:project).try(:trackers)
      elsif params[:project_id]
        Project.find_by(id: params[:project_id]).try(:trackers)
      end
    end

    render :json => @allowed_trackers.to_a.collect { |t| { :text => t.name, :value => t.id } }
  end

  def issue_priorities
    render :json => IssuePriority.active.collect { |p| { :text => p.name, :value => p.id } }
  end

  def assignable_users
    entity_type = begin
      ; (params[:entity_type] || 'Issue').constantize;
    rescue;
    end
    return render_404 if entity_type.nil?
    @entity = entity_type.find_by(id: (params[:entity_id] || params[:issue_id]))
    @entity ||= entity_type.new
    if params[:project_id] && @entity.respond_to?(:project)
      @entity.project = Project.find_by(id: params[:project_id])
    end
    select_options = entity_assigned_to_collection_for_select_options(@entity, params[:project_id], external: params[:external])

    if params[:easy_autocomplete]
      users = select_options.map { |k, v| v }.first.map { |o| { value: o.first, id: o.last } }
      json  = { users: users }
    else
      json = select_options.map { |o| { text: o[0], children: o[1].map { |i| { i[1].to_s => i[0].to_s } } } }
      if @entity.is_a?(Issue) && !User.current.limit_assignable_users_for_project?(@entity.project)
        json.prepend(['', ''])
      end
    end

    render json: json
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def assignable_principals_issue
    entity   = Issue.find_by(id: params[:issue_id])
    entity   ||= Issue.new
    project  = entity.project
    project  ||= Project.find_by(id: params[:project_id]) if params[:project_id]
    projects = Project.where(id: params[:project_ids]).to_a if params[:project_ids]
    projects ||= [project]
    return render_404 unless projects.any?

    assignable_principals = EasyPrincipalQuery.get_assignable_principals(projects, params[:term]).sorted
    limited_users = User.current.limit_assignable_users_for_project?(project)
    if limited_users
      assignable_principals = assignable_principals.where(id: [User.current, entity.author].compact)
    end
    assignable_principals_base(entity, assignable_principals.to_a, limited_users: limited_users)
  end

  def managed_users
    users             = get_active_users
    users_for_options = []
    if users.include?(User.current)
      users_for_options = [{ text: "<< #{l(:label_me)} >>".html_safe, value: User.current.id }]
    end
    users_for_options += users.map { |user| { text: user.to_s, value: user.id } }

    render json: users_for_options
  end

  def attendance_report_users
    report_users = []
    if User.current.allowed_to_globally?(:view_easy_attendance_other_users)
      term                 = params[:term]
      scope                = Principal.active.non_system_flag.sorted
      scope                = if /^\d+$/.match?(term)
                               scope.where(id: term)
                             else
                               scope.like(term)
                             end
      include_current_user = scope.where(id: User.current.id).exists?
      report_users         = scope.limit(EasySetting.value('easy_select_limit').to_i).to_a.map { |p| { value: p.name, id: p.id } }
      if include_current_user
        report_users.prepend({ value: "<< #{l(:label_me)} >>", id: User.current.id })
      end
    else
      report_users.prepend({ value: "<< #{l(:label_me)} >>", id: User.current.id })
    end
    render json: { users: report_users }
  end

  def assignable_versions
    @issue  = Issue.find(params[:issue_id])
    options = [['', '']]
    options.concat(@issue.assignable_versions.map { |v| { text: v.name, value: v.id } })

    render :json => options
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def versions
    scope    = Version.visible.open_and_locked.like(params[:term]).joins(:project).where(projects: { easy_is_easy_template: false })
    versions = Version.values_for_select_with_project(scope)

    versions.map! do |(name, id)|
      { id: id, value: name }
    end
    versions.prepend({ id: '', value: "--- #{l(:label_in_modules)} ---" }) if params[:include_system_options]&.include?('no_filter')

    render json: versions
  end

  def users_for_query_copy
    easy_query = EasyQuery.find_by(id: params[:easy_query_id]) if params[:easy_query_id]
    return render_404 if easy_query.nil?

    users_having_query = easy_query.query_copies.preload(:user).inject({}) do |users, query_copy|
      users[query_copy.user_id] = query_copy.user.name if query_copy.user&.visible?
      users
    end

    @users = get_active_users_scope(params[:term], EasySetting.value('easy_select_limit').to_i)
    @users = @users.where.not(id: users_having_query.keys)
    @users = @users.where(id: easy_query.project.members.pluck(:user_id)) if easy_query.project.present?

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/users_with_id', :formats => [:api] }
    end
  end

  def users
    @users = get_active_users_scope(params[:term], EasySetting.value('easy_select_limit').to_i).to_a

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/users_with_id', :formats => [:api] }
    end
  end

  def internal_users
    @users = get_active_internals_users_scope(params[:term], EasySetting.value('easy_select_limit').to_i).to_a

    @additional_options = []
    unless params[:term].present?
      @additional_options << ["--- #{l(:label_in_modules)} ---", ''] if params[:include_system_options]&.include?('no_filter')
      @additional_options << ["<< #{l(:label_me)} >>", 'me'] if params[:include_peoples]&.include?('me')
      call_hook(:controller_easy_auto_complete_internal_users, { additional_options: @additional_options })
    end
    respond_to do |format|
      format.api { render template: 'easy_auto_completes/users_with_id', locals: { additional_select_options: @additional_options }, formats: [:api] }
    end
  end

  def users_in_meeting_calendar
    @users = get_active_users_in_meeting_calendar_scope(params[:term], EasySetting.value('easy_select_limit').to_i).to_a
    @users.unshift(Struct.new(:id, :name).new('me', "<< #{l(:label_me)} >>")) if params[:include_me].present?

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/users_with_id', :formats => [:api] }
    end
  end

  def grouped_users_in_meeting_calendar
    users = get_active_users_in_meeting_calendar_scope(params[:term], EasySetting.value('easy_select_limit').to_i).to_a

    assignable_principals_base(nil, users)
  end

  def principals
    @users = get_active_principals_scope(params[:term], EasySetting.value('easy_select_limit').to_i).to_a

    @additional_options = []
    unless params[:term].present?
      call_hook(:controller_easy_auto_complete_principals, { additional_options: @additional_options })
    end

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/users_with_id', locals: { additional_select_options: @additional_options }, formats: [:api] }
    end
  end

  def visible_principals
    source_options = params_for_remote_autocomplete
    principals = visible_principals_values(options: source_options.merge(no_limit: true))
    @additional_select_options = principals_additional_autocomplete_options(principals, options: source_options)
    limit = EasySetting.value('easy_select_limit').to_i
    @users = principals.limit(limit)
    respond_to do |format|
      format.api { render template: 'easy_auto_completes/users_with_id', formats: [:api], locals: { additional_select_options: @additional_select_options } }
    end
  end

  def visible_user_groups
    groups = get_all_available_user_groups(params[:term], EasySetting.value('easy_select_limit').to_i)
    groups = groups.map do |group|
      { id: group.id, value: group.name }
    end

    render json: groups
  end

  def tags
    tags = get_all_available_tags(params[:term], EasySetting.value('easy_select_limit').to_i)
    tags = tags.map do |tag|
      { id: tag, value: tag }
    end

    render json: tags
  end

  def issue_author_values
    issue = Issue.find(params[:issue_id])
    users = (get_project_users_scope(issue.project).to_a + Array(issue.author)).uniq.collect { |u| { :text => u.name, :value => u.id } }

    render :json => users
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def custom_field_possible_values
    cf = CustomField.find(params[:custom_field_id])

    render :json => cf.possible_values.map { |name, code| { text: name, value: code } }
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def time_entry_activities
    @available_activities = TimeEntryActivity.shared.sorted
    activities            = @available_activities.map { |tea| { text: tea.name, value: tea.id } }
    activities.unshift({ text: '', value: '' }) if params[:include_blank].present?
    render json: activities
  end

  def saved_filters
    values        = {}
    saved_queries = EasyQuery.preload(:user).named(params[:entity_type], params[:term].to_s)
    saved_queries.each do |x|
      if values[x.user_id]
        values[x.user_id][:children] << { x.id => x.name }
      else
        values[x.user_id] = { text: x.user ? x.user.name : I18n.t(:label_nobody), children: [{ x.id => x.name }] }
      end
    end
    render :json => values.values
  end

  def easy_entity_activity_category
    render :json => EasyEntityActivityCategory.sorted.collect { |s| { :text => s.name, :value => s.id } }
  end

  def easy_entity_activity_attendees
    render :json => { easy_entity_activity_attendees: EasyEntityActivityAttendee.all_attendees_values(params[:term], EasySetting.value('easy_select_limit').to_i) }
  end

  # ckeditor
  # @login
  def ckeditor_users
    @entities = User.active.easy_type_internal.with_easy_avatar.visible.where(easy_system_flag: false).
        where(Redmine::Database.like("#{User.table_name}.login", '?'), "#{params[:query]}%").
        limit(EasySetting.value('easy_select_limit').to_i).sorted

    respond_to do |format|
      format.json { render json: @entities.map { |e| { id: e.id, name: e.login, full_name: e.name, avatar: avatar_url(e) } } }
    end
  end

  # #123
  def ckeditor_issues
    column    = "#{Issue.table_name}.id"
    column    = "CAST(#{column} AS TEXT)" if Redmine::Database.postgresql?
    @entities = Issue.visible.where(Redmine::Database.like(column, '?'), "#{params[:query]}%").
        limit(EasySetting.value('easy_select_limit').to_i)

    respond_to do |format|
      format.json { render json: @entities.map { |e| { id: e.id, name: e.id, subject: e.subject } } }
    end
  end

  # attachment:
  def ckeditor_attachments
    if params[:entity_id]
      entity_id   = params[:entity_id]
      entity_type = params[:entity_type]
      entity = entity_type.constantize.find(entity_id) rescue nil
      if entity.respond_to?(:attachments)
        scope = entity.attachments
      else
        scope = Attachment.none
      end
    else
      scope = Attachment.none # new record
    end

    @entities = scope.preload(:container).where(Redmine::Database.like("#{Attachment.table_name}.filename", '?'), "#{params[:query]}%").
        limit(EasySetting.value('easy_select_limit').to_i).select(&:visible?)

    respond_to do |format|
      format.json { render json: @entities.map { |e| { id: e.id, name: e.filename, subject: e.filename } } }
    end
  end

  def project_entities
    entity_klass = params[:entity_type].safe_constantize if params[:entity_type]
    return render_404 unless entity_klass
    @entities = entity_klass.visible.like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i)
    if params[:project_id] && entity_klass.column_names.include?('project_id')
      @entities = @entities.where(project_id: params[:project_id])
    end
    @name_column = :to_s

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: { additional_select_options: false } }
    end
  end

  def issue_categories
    categories = IssueCategory.where(project_id: params[:project_id]).
      like(params[:term]).
      limit(EasySetting.value('easy_select_limit').to_i).
      order(:name)

    respond_to do |format|
      format.json { render json: categories.collect { |c| { text: c.name, value: c.id } } }
    end
  end

  private

  def set_self_only
    @self_only = params[:term].blank?
  end

  def assignable_principals_base(entity, assignable_principals, options = {})
    struct           = Struct.new(:name, :id, :principal)
    default_category = { '' => [] }
    if params['term'].blank?
      default_category[''] << struct.new(l(:label_no_change_option), '') if params[:move] == 'true'
      default_category[''] << struct.new("<< #{l(:label_nobody)} >>", 'none') if params[:required] != 'true' && !options[:limited_users]
      default_category[''] << struct.new("<< #{l(:label_me)} >>", User.current.id, User.current) if assignable_principals.include?(User.current)
      if entity && !entity.new_record?
        default_category[''] << struct.new(l(:label_author_assigned_to), entity.author.id, entity.author) if entity.author&.active?
        if entity.respond_to?(:last_user_assigned_to) && !options[:limited_users]
          if ((entity.last_user_assigned_to.is_a?(User) && entity.last_user_assigned_to.active? && assignable_principals.include?(entity.last_user_assigned_to)) ||
              (entity.last_user_assigned_to.is_a?(Group) && Setting.issue_group_assignment? && assignable_principals.include?(entity.last_user_assigned_to))) && entity.assigned_to_id != entity.last_user_assigned_to.id
            default_category[''] << struct.new(l(:label_last_user_assigned_to), entity.last_user_assigned_to.id, entity.last_user_assigned_to)
          end
        end
      end
    end
    render json: principals_options_for_autocomplete(assignable_principals, default_category, entity)
  end

  def get_available_parent_issues(project, term = '', limit = nil)
    if term =~ /^\d+$/
      Array(Issue.cross_project_scope(project, Setting.cross_project_subtasks).visible.find_by(id: term))
    else
      Issue.cross_project_scope(project, Setting.cross_project_subtasks).visible.like(term).order(:subject).limit(limit).to_a
    end
  end

  def get_visible_projects_scope(term = '', limit = nil)
    if /^\d+$/.match?(term)
      scope = Project.where(id: term)
    else
      scope = Project.sorted.like(term).limit(limit).sorted
    end
    scope.visible.non_templates
  end

  def get_template_projects_scope(term = '', limit = nil)
    if /^\d+$/.match?(term)
      scope = Project.templates.where(id: term)
    else
      scope = Project.templates.like(term).limit(limit).sorted
    end
    scope.visible
  end

  def get_template_projects(term = '', limit = nil)
    get_template_projects_scope(term, limit).to_a
  end

  def get_visible_projects(term = '', limit = nil)
    get_visible_projects_scope(term, limit).to_a
  end

  def get_visible_projects_with_permission(permission, term = '', limit = nil)
    get_visible_projects_scope(term, limit).allowed_to(permission).to_a
  end

  def get_scope_without_used_users(scope)
    if params[:used_user_ids].present?
      users_from_used_groups = scope.joins(:groups).where(users_groups_users_join: {group_id: params[:used_user_ids]}).pluck(:user_id)
      scope = scope.where.not(id: (params[:used_user_ids] | users_from_used_groups))
    end
    scope
  end

  def get_active_users_scope(term = '', limit = nil)
    if /^\d+$/.match?(term)
      scope = User.active.where(id: term)
    else
      scope = User.active.like(term).limit(limit).sorted
    end
    scope.visible
  end

  def get_active_internals_users_scope(term = '', limit = nil)
    get_active_users_scope(term, limit).easy_type_internal
  end

  def get_active_users_in_meeting_calendar_scope(term = '', limit = nil)
    scope = get_active_users_scope(term, limit)
    if params[:used_user_ids].present?
      scope = get_scope_without_used_users(scope.users_in_meeting_calendar)
      scope += get_non_used_groups(term, limit) if params[:include_groups].present?
    else
      scope = scope.users_in_meeting_calendar
      scope += get_all_available_user_groups(term, limit) if params[:include_groups].present?
    end
    scope
  end

  def get_all_available_tags(term = '', limit = nil)
    ActsAsTaggableOn::Tag
        .joins(:taggings)
        .where(taggings: { context: 'tags' })
        .where("LOWER(name) LIKE LOWER(:p)", p: "%#{term}%")
        .limit(limit)
        .distinct.pluck(:name)
  end

  def get_all_available_user_groups(term = '', limit = nil)
    Group.visible.givable.like(term).limit(limit).sorted
  end

  # @return groups, that fulfill all:
  # - aren't already selected (eg param[:used_user_ids] )
  # - are a match for the input of the search (term)
  # - are visible for the current user (default Principal.visible scope for the group & it's members)
  def get_non_used_groups(term = '', limit = nil)
    groups = Group.visible.givable.like(term) # all visible & matching
    if params[:used_user_ids].present?
      groups = groups.where.not(id: params[:used_user_ids]) # exclude already selected groups
    end
    groups = groups.joins(:groups_users).where(groups_users: {user_id:  User.active.visible.select(:id)}).distinct
    groups.limit(limit).sorted
  end

  def get_active_principals_scope(term = '', limit = nil)
    if /^\d+$/.match?(term)
      scope = Principal.active.where(id: term)
    else
      scope = Principal.active.like(term).limit(limit).sorted
    end
    scope.visible
  end

  def get_project_users_scope(project, term = '', limit = nil)
    if /^\d+$/.match?(term)
      scope = project.users.active.non_system_flag.where(id: term)
    else
      scope = project.users.active.non_system_flag.like(term).limit(limit).sorted
    end
    scope.visible
  end

  def get_issues_with_parents(term = '', limit = nil)
    if /^\d+$/.match?(term)
      Array(Issue.visible.where.not(parent_id: nil).joins(:project).where(projects: { easy_is_easy_template: false }).find_by(id: term))
    else
      Issue.visible.where.not(parent_id: nil).joins(:project).where(projects: { easy_is_easy_template: false }).like(term).limit(limit).to_a
    end
  end

  def get_root_issues(term = '', limit = nil)
    if /^\d+$/.match?(term)
      Array(Issue.visible.where(parent_id: nil).joins(:project).where(get_project_if_exist).find_by(id: term))
    else
      Issue.visible.where(parent_id: nil).joins(:project).where(get_project_if_exist).like(term).limit(limit).to_a
    end
  end

  def get_visible_issues(term = '', limit = nil)
    if term =~ /^\d+$/
      Array(Issue.visible.joins(:project).where(get_project_if_exist).find_by(id: term))
    else
      Issue.visible.joins(:project).where(get_project_if_exist).like(term).limit(limit).to_a
    end
  end

  def params_for_remote_autocomplete
    options = params[:source_options]&.to_unsafe_h || {}
    options.merge(term: params[:term] || '')
  end

  def get_active_users
    User.active.visible.non_system_flag.easy_type_internal.sorted.to_a
  end

end
