module EasyEntityImports
  class EasyAsanaCsvImport < EasyEntityCsvImport

    attr_reader :logger

    def initialize(_attributes = nil)
      @logger = EasyEntityImports::ImportLogger.new
    end

    # @note Removes this class from available EasyEntityImports
    #   see: plugins/easyproject/easy_plugins/easy_extensions/app/views/easy_entity_imports/index.html.erb:9
    def self.disabled?
      true
    end

    def import(file)
      begin
        csv = CSV.new(File.new(file, encoding: 'bom|utf-8'), headers: true).read
      rescue StandardError
        @logger.log_fatal_error(I18n.t('easy_imports.file_could_not_be_processed'))
        return false
      end

      required_headers = ['Task ID', 'Created At', 'Completed At', 'Last Modified', 'Name', 'Assignee', 'Due Date', 'Tags', 'Notes', 'Projects', 'Parent Task']

      if (missing_headers = (required_headers - csv.headers)).any?
        headers = missing_headers.map { |e| e.capitalize }.join(', ')
        @logger.log_fatal_error("#{I18n.t('easy_imports.file_could_not_be_processed')} #{I18n.t('easy_imports.missing_required_headers', headers: headers)}")
        return false
      end

      attribute_assignments = [
          EasyEntityImportAttributesAssignment.new(source_attribute: 'Task ID', entity_attribute: 'easy_external_id'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'Name', entity_attribute: 'subject'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'Notes', entity_attribute: 'description'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'Created At', entity_attribute: 'created_on'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'Last Modified', entity_attribute: 'updated_on'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'Due Date', entity_attribute: 'due_date')
      ]
      issues                = {}
      projects_by_name      = {}
      users_by_name         = {}
      issues_by_name        = {}
      fallback_tracker_id   = Tracker.first.id
      fallback_status_id    = IssueStatus.first.id
      fallback_priority_id  = IssuePriority.first.id
      Issue.transaction do
        csv.each do |line|
          next unless line.fetch('Name')

          unless project = find_or_create_project(line, issues_by_name, projects_by_name)
            issue = Issue.new(name: line.fetch('Name'))
            @logger.log_entity_error(issue, nil, "#{I18n.t('easy_imports.issue_could_not_be_created', issue_name: xpath['summary'])} #{I18n.t('easy_imports.no_project_for_task')}")
            next
          end

          unless (issue = Issue.find_by(easy_external_id: line.fetch('Task ID')))
            warnings             = []
            issue                = Issue.new
            issue.project        = project
            issue.tracker_id     = project.tracker_ids.first || fallback_tracker_id
            issue.author_id      = User.current.id
            issue.parent_id      = issues_by_name[line.fetch('Parent Task')].try(:id)
            issue.assigned_to_id = find_user(line, users_by_name)
            issue.priority_id    = fallback_priority_id
            issue.status_id      = fallback_status_id
            assign_attribute_for(issue, attribute_assignments, line)

            begin
              warnings.concat(issue.errors.full_messages) unless issue.valid?
              issue.save(validate: false)
              @logger.log_entity_creation issue
              @logger.log_entity_warning(issue, nil, warnings) if warnings.any?
            rescue
              @logger.log_entity_error(issue, project.id, "#{I18n.t('easy_imports.issue_could_not_be_created', issue.subject)}<ul>#{issue.errors.full_messages.map { |m| "<li>#{m}</li>" }.join}</ul>".html_safe)
            end
          else
            @logger.log_entity_mapping issue
          end
          issues_by_name.store(issue.subject, issue)
          issues.store(issue.easy_external_id, issue.id)
        end
      end

      return true
    end

    def log
      @logger.log
    end

    private

    def assign_attribute_for(entity, assignments, line)
      assignments.each do |attrs|
        entity.send("#{attrs.entity_attribute}=", line.fetch(attrs.source_attribute))
      end
    end

    def find_or_create_project(line, issues_by_name, projects_by_name)
      project_name = line.fetch('Projects').presence
      project_name ||= issues_by_name[line.fetch('Parent Task')].try(:project).try(:name)
      return unless project_name

      if project = projects_by_name[project_name]
      elsif project = Project.find_by(name: project_name)
        projects_by_name[project_name] = project
        @logger.log_entity_mapping project
      else
        project = Project.new(name: project_name)
        project.enable_module!('easy_wbs')

        begin
          warnings = (project.errors.full_messages) unless project.valid?
          raise unless EasyLicenseManager.has_license_limit?(:active_project_limit)
          project.save!(validate: false)
          projects_by_name[project_name] = project
          project.init_overview_page
          @logger.log_entity_creation project
          @logger.log_entity_warning(project, nil, warnings) if warnings.present?
        rescue
          @logger.log_entity_error(project, project.name, "#{I18n.t('easy_imports.project_could_not_be_created', project_name: project.name)}<ul>#{project.errors.full_messages.map { |m| "<li>#{m}</li>" }.join}</ul>".html_safe)
          project = nil
        end
      end
      project
    end

    def find_user(line, users_by_name)
      user_name = line.fetch('Assignee').presence
      return unless user_name
      users_by_name.has_key?(user_name) ? users_by_name[user_name] : users_by_name[user_name] = User.like(line.fetch('Assignee')).first
    end

  end
end
