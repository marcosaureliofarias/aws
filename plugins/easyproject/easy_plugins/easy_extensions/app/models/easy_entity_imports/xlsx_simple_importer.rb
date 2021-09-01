require 'roo'
require 'roo-xls'

module EasyEntityImports
  class XlsxSimpleImporter

    attr_reader :logger

    def initialize
      @logger = EasyEntityImports::ImportLogger.new
      @map    = Hash.new { |k, v| k[v] = {} }
    end

    def import(xlsx_file = nil)
      rows = parse_file(xlsx_file)
      return false unless rows

      current_project = nil
      rows.each do |row|
        next if row.blank?
        if row[:project].present?
          current_project = Project.new(name: row[:project])
          current_project.enable_module!('easy_wbs')
          begin
            warnings = (current_project.errors.full_messages) unless current_project.valid?
            raise unless EasyLicenseManager.has_license_limit?(:active_project_limit)
            current_project.save!(validate: false)
            current_project.init_overview_page
            @logger.log_entity_creation current_project
            @logger.log_entity_warning(current_project, nil, warnings) if warnings.present?
          rescue
            @logger.log_entity_error(current_project, current_project.name, "#{I18n.t('easy_imports.project_could_not_be_created', project_name: current_project.name)}<ul>#{current_project.errors.full_messages.map { |m| "<li>#{m}</li>" }.join}</ul>".html_safe)
            current_project = nil
          end
        else
          next if row[:issue].blank? || current_project.nil?
          warnings      = []
          issue         = Issue.new
          issue.subject = row[:issue]
          issue.project = current_project

          if row[:assignee].present?
            issue.assigned_to = find_existing_entity(row, :assignee, User)
            warnings << "#{I18n.t('easy_imports.could_not_find_user', user_name: row[:assignee])} #{I18n.t('easy_imports.assignee_set_to_nobody')}" if issue.assigned_to.nil?
          end

          issue.priority = get_attribute_value(row, :priority, IssuePriority)
          warnings << "#{I18n.t('easy_imports.could_not_find_issue_priority', priority_name: row[:priority])} #{I18n.t('easy_imports.issue_priority_set_to_value', priority_name: issue.priority)}" if @logger.get_errors_for(:issue_priorities, row[:priority]).present?

          issue.status = get_attribute_value(row, :status, IssueStatus)
          warnings << "#{I18n.t('easy_imports.could_not_find_issue_status', status_name: row[:status])} #{I18n.t('easy_imports.issue_status_set_to_value', status_name: issue.status)}" if @logger.get_errors_for(:issue_statuses, row[:status]).present?

          issue.tracker = get_attribute_value(row, :tracker, Tracker, entity_creation_attr: issue.status)
          warnings << "#{I18n.t('easy_imports.could_not_find_tracker', tracker_name: row[:tracker])} #{I18n.t('easy_imports.tracker_set_to_value', tracker_name: issue.tracker)}" if @logger.get_errors_for(:trackers, row[:tracker]).present?

          if row[:due_date].present?
            issue.due_date = parse_date(row[:due_date])
            warnings << "#{row[:due_date]} #{I18n.t('activerecord.errors.messages.not_a_date')}." if issue.due_date.nil?
          end

          if row[:parent].present?
            issue.parent_id = find_in_map(row, :parent, Issue).try(:id)
            warnings << "#{I18n.t('easy_imports.could_not_find_task', entity_name: row[:parent])} #{I18n.t('easy_imports.parent_task_was_not_set')}" if issue.parent_id.nil?
          end

          issue.description = row[:description] if row[:description]
          issue.author      = User.current

          issue.project.trackers << issue.tracker unless current_project.trackers.include? issue.tracker

          begin
            warnings.concat(issue.errors.full_messages) unless issue.valid?
            issue.save(validate: false)
            @logger.log_entity_creation issue
            @logger.log_entity_warning(issue, nil, warnings) if warnings.any?
            save_to_map(row, :issue, issue)
          rescue
            @logger.log_entity_error(issue, current_project.id, "#{I18n.t('easy_imports.issue_could_not_be_created', issue_name: row[:issue])}<ul>#{issue.errors.full_messages.map { |m| "<li>#{m}</li>" }.join}</ul>".html_safe)
          end
        end
      end
      true
    end

    def log
      @logger && @logger.log
    end

    private

    def parse_file(xlsx_file)
      begin
        @xlsx = Roo::Spreadsheet.open(xlsx_file)
      rescue
        @logger.log_fatal_error(I18n.t('easy_imports.file_could_not_be_processed'))
        return false
      end

      header_row = @xlsx.first_row ? @xlsx.row(@xlsx.first_row).compact : []
      header_row.each { |key| key.try(:strip!); key.try(:gsub!, ' ', '_'); key.try(:downcase!) }

      return false unless validate_required_columns(header_row)
      set_header_keys header_row
      @xlsx.parse(@header_keys)
    end

    def get_attribute_value(row, key, klass, options = {})
      if !(@header_keys[key]) || !(row[key])
        return default_value_for(key)
      else
        find_existing_entity(row, key, klass) || create_new_entity_by_name(row, key, klass, options) || default_value_for(key, row, klass)
      end
    end

    def create_new_entity_by_name(row, key, klass, options = {})
      method_name = "create_#{klass.name.underscore}"
      if respond_to?(method_name, true)
        send(method_name, *[row[key], options[:entity_creation_attr]].compact)
      end
    end

    def find_in_map(row, key, klass)
      entity_type = klass.name.underscore.to_sym
      @map[entity_type].has_key?(row[key]) ? @map[entity_type][row[key]] : nil
    end

    def save_to_map(row, key, entity, klass = nil)
      klass                                        ||= entity.class
      @map[klass.name.underscore.to_sym][row[key]] = entity
    end

    def key_mapped?(row, key, klass)
      @map[klass.name.underscore.to_sym].has_key?(row[key])
    end

    def find_existing_entity(row, key, klass)
      return nil if row[key].blank?
      if !(entity = find_in_map(row, key, klass) && !(key_mapped?(row, key, klass)))
        entity = klass.find_by(name: row[key]) if klass.column_names.include?('name')
        if !entity && klass.respond_to?(:like)
          entity = klass.like(row[key]).first
        end
        if entity
          save_to_map(row, key, entity)
          @logger.log_entity_mapping(entity)
        end
      end
      entity
    end

    def default_value_for(key, row = nil, klass = nil)
      init_default_values unless @default_values
      default_value = @default_values[key]
      if row && klass
        save_to_map(row, key, default_value, klass)
      end
      default_value
    end

    def init_default_values
      @default_values            = {}
      @default_values[:priority] = IssuePriority.default || IssuePriority.first || create_issue_priority('Default Task Priority')
      @default_values[:status]   = IssueStatus.find_by(is_closed: false) || IssueStatus.first || create_issue_status('Default Issue Status')
      @default_values[:tracker]  = Tracker.first || create_tracker('Default Tracker', @default_values[:status])
    end

    # not used atm
    # def create_user(name)
    #   return nil if name.blank?
    #   first_name, last_name = name.split(' ', 2)
    #   login = name.parameterize.gsub('-', '_')
    #   user = User.new(firstname: first_name, lastname: last_name, mail: "#{login}@example.com")
    #   user.login = login
    #
    #   if user.save
    #     @map[:assignee][name] = user
    #   else
    #     @logger.log_entity_error(user, name, "User with name #{name} could not be created. Issue assignee set to nobody")
    #     user = nil
    #   end
    #   user
    # end

    def create_issue_priority(name)
      return if name.blank?
      issue_priority = IssuePriority.new(name: name)

      if issue_priority.save
        @map[:priority][name] = issue_priority
        @logger.log_entity_creation issue_priority
      else
        @logger.log_entity_error(issue_priority, name, "#{I18n.t('easy_imports.could_not_find_issue_priority', priority_name: name)} #{I18n.t('easy_imports.issue_priority_set_to_default_value')}")
        issue_priority = nil
      end
      issue_priority
    end

    def create_tracker(name, status)
      return if name.blank?
      tracker                = Tracker.new(name: name)
      tracker.default_status = status

      if tracker.save
        @map[:tracker][name] = tracker
        @logger.log_entity_creation tracker
      else
        @logger.log_entity_error(tracker, name, "#{I18n.t('easy_imports.could_not_find_tracker', tracker_name: name)} #{I18n.t('easy_imports.tracker_set_to_default_value')}")
        tracker = nil
      end
      tracker
    end

    def create_issue_status(name)
      return if name.blank?
      issue_status = IssueStatus.new(name: name)

      if issue_status.save
        @map[:status][name] = issue_status
        @logger.log_entity_creation issue_status
      else
        @logger.log_entity_error(issue_status, name, "#{I18n.t('easy_imports.could_not_find_issue_status', issue_status: name)} #{I18n.t('easy_imports.issue_status_set_to_default_value')}")
        issue_status = nil
      end
      issue_status
    end

    def valid_columns
      return @valid_columns if @valid_columns

      available_locales = I18n.available_locales
      valid_column_keys = { project:     :label_project,
                            issue:       :label_issue,
                            due_date:    :field_due_date,
                            assignee:    :field_assigned_to,
                            priority:    :field_priority,
                            status:      :field_status,
                            tracker:     :field_tracker,
                            description: :field_description,
                            parent:      :field_parent_issue }

      @valid_columns = {}
      valid_column_keys.each do |column_key, lang_key|
        @valid_columns[column_key] = {}
        available_locales.each do |locale|
          @valid_columns[column_key][locale] = I18n.t(lang_key, locale: locale)
        end
      end

      @valid_columns
    end

    def required_columns
      [:project, :issue]
    end

    def set_header_keys(columns)
      return @header_keys if @header_keys
      formatted_columns = columns.map { |column| column.to_s.parameterize.underscore }
      @header_keys      = {}

      valid_columns.map do |column_key, translations|
        translations.values.any? { |translated_name| (index = formatted_columns.index(translated_name.parameterize.underscore)) && @header_keys[column_key] = columns[index] }
      end

      @header_keys
    end

    # not used atm
    # def collect_data(rows)
    #   data = Hash.new{|k, v| k[v] = []}
    #
    #   rows.each do |row|
    #     data[:users] << row[:assignee] if row[:assignee]
    #     data[:priorities] << row[:priority] if row[:priority]
    #     data[:statuses] << row[:status] if row[:status]
    #     data[:trackers] << row[:tracker] if row[:tracker]
    #   end
    #
    #   data.each {|_, v| v.uniq!; v.compact! }
    # end

    def validate_required_columns(columns)
      columns         = columns.map { |column| column.to_s.parameterize.underscore }
      missing_columns = required_columns.select do |required_column|
        column_found = false
        valid_columns[required_column].values.each { |required_column_name| break if (column_found = columns.include?(required_column_name.parameterize.underscore)) }
        !column_found
      end

      if missing_columns.any?
        headers = missing_columns.map { |column_key| (valid_columns[column_key][I18n.locale] || valid_columns[column_key][:en]) }.join(', ')
        @logger.log_fatal_error "#{I18n.t('easy_imports.file_could_not_be_processed')} #{I18n.t('easy_imports.missing_required_headers', headers: headers)}"
        return false
      else
        return true
      end
    end

    def parse_date(date)
      if date.is_a?(Date)
        date
      else
        Date.parse(date) rescue nil
      end
    end
  end
end
