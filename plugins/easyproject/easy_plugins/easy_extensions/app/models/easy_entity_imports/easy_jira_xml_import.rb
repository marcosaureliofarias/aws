module EasyEntityImports
  class EasyJiraXmlImport < EasyEntityXmlImport
    attr_reader :results

    PLACEHOLDER_STRUCT = Struct.new(:easy_external_id, :id)

    def initialize(_attributes = nil)
      @logger = EasyEntityImports::ImportLogger.new
    end

    def prepare_files(file)
      @tmp_dir = Dir.mktmpdir

      begin
        Zip.warn_invalid_date = false
        Zip::File.open(file) do |zip_file|
          zip_file.each do |f|
            fpath = File.join(@tmp_dir, f.name)
            FileUtils.mkdir_p(File.dirname(fpath))
            zip_file.extract(f, fpath) unless File.exist?(fpath)
          end
        end
        Dir[@tmp_dir + '/entities.xml'].blank? ? Dir[@tmp_dir + '/*'].first : @tmp_dir
      rescue
        nil
      ensure
        Zip.warn_invalid_date = true
      end
    end

    def import(file = nil, options = {})
      begin
        if File.extname(file) == '.xml'
          @entities_file = file
        elsif (root_directory = prepare_files(file))
          @entities_file_path = File.join(root_directory, 'entities.xml')
          @entities_file      = File.open @entities_file_path if File.exist? @entities_file_path
        end

        User.current.as_admin do
          @results = {}

          begin
            @xml = Nokogiri::XML.parse(@entities_file.read) if @entities_file
          rescue
            @logger.log_fatal_error(I18n.t('easy_imports.file_could_not_be_processed'))
            puts @logger.log[:fatal_error]
            return false
          end

          Mailer.with_deliveries(false) do
            start = Time.now
            run_imports
            duration = duration_in_minutes(start)
            puts "Jira import finished after #{duration} minutes."
          end
        end

        if @results.find { |_, v| v.present? }
          true
        else
          @logger.log_fatal_error(I18n.t('easy_imports.no_valid_data_found'))
          puts @logger.log[:fatal_error]
          false
        end
      ensure
        unless options[:do_not_delete_file]
          if @tmp_dir && File.exist?(@tmp_dir)
            FileUtils.remove_entry @tmp_dir
          elsif @entities_file && File.exist?(@entities_file)
            FileUtils.remove_entry @entities_file
          end
        end
      end
    end

    def duration_in_minutes(start)
      ((Time.now - start) / 60).round(2)
    end

    def import_entities(type, collection)
      start     = Time.now
      type_name = type.underscore.pluralize
      if respond_to?("import_#{type_name}", true)
        @results[type_name.to_sym] = send("import_#{type_name}", collection)
      else
        entities = {}
        klass    = type.constantize
        klass.transaction do
          collection.each do |xpath|
            unless (entity = klass.find_by(name: xpath['name']))
              entity = klass.new(name: xpath['name'].truncate(30), position: xpath['sequence'], easy_external_id: xpath['id'])
              entity.save!(validate: false)
              @logger.log_entity_creation entity
            else
              @logger.log_entity_mapping entity
            end
            entities.store(entity.easy_external_id, entity.id)
          end
        end

        @results[type_name.to_sym] = entities
      end
      duration = duration_in_minutes(start)
      puts "Jira importer import #{type} successfully. Duration #{duration} minutes."
    end

    def import_attachments(folder = './data/attachments')
      start                   = Time.now
      f                       = File.expand_path(folder)
      xml_attachments         = @xml.xpath('//FileAttachment')
      existing_attachment_ids = Attachment.where(easy_external_id: xml_attachments.map { |xml| xml['id'] }).pluck(:easy_external_id)
      Attachment.transaction do
        User.current.as_admin do
          xml_attachments.each do |xpath|
            next if existing_attachment_ids.include?(xpath['id'])
            issue_id  = get_issue_id(xpath['issue'])
            author_id = get_user_id(xpath['author'])
            file      = Pathname(%x(find #{f} -name "#{xpath['id']}" -type f).strip)
            if file.exist? && issue_id
              begin
                ; date = Time.parse(xpath['created']) rescue nil;
              end
              File.open(file) do |t|
                begin
                  Attachment.create!(file: t, filename: xpath['filename'], author_id: author_id || User.current.id, container_type: 'Issue', container_id: issue_id, easy_external_id: xpath['id'], created_on: date)
                rescue
                  puts "File #{t.path} could not be imported"
                end
              end
            end
          end
        end
      end
      duration = duration_in_minutes(start)
      puts "Jira importer import Attachments successfully. Duration #{duration} minutes."
    end

    def get_issue_id(jira_issue)
      raise ArgumentError.new('You need to process issues firstly !') if @results[:issues].nil?
      @results[:issues][jira_issue].presence
    end

    def get_user_id(jira_login)
      raise ArgumentError.new('You need to process users firstly !') if @results[:users].nil?
      easy_login = convert_jira_login_to_easy_login(jira_login)
      @results[:users][easy_login].presence
    end

    def convert_jira_login_to_easy_login(jira_login)
      return nil unless jira_login
      jira_login.downcase.gsub(/[^a-z0-9_\-@\.]/, '_')
    end

    def log
      @logger.log
    end

    private

    def import_customfields
      start                       = Time.now
      xml_custom_fields           = @xml.xpath('//CustomField')
      custom_fields               = {}
      existing_custom_field_names = CustomField.pluck(:name)
      existing_custom_fields      = CustomField.where(easy_external_id: xml_custom_fields.map { |xpath| xpath['id'] })
      xml_custom_fields.each do |xpath|
        unless (cf = existing_custom_fields.find { |custom_field| custom_field.easy_external_id == xpath['id'] })
          cf = case xpath['customfieldtypekey']
               when 'com.atlassian.jira.plugin.system.customfieldtypes:multiselect'
                 IssueCustomField.new(field_format: 'list', multiple: true)
               when 'com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes'
                 IssueCustomField.new(field_format: 'list', multiple: true, edit_tag_style: 'check_box')
               when 'com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons'
                 IssueCustomField.new(field_format: 'list', multiple: false, edit_tag_style: 'check_box')
               when 'com.atlassian.jira.plugin.system.customfieldtypes:float'
                 IssueCustomField.new(field_format: 'float')
               end
          next if cf.nil?

          name = xpath['name']
          while existing_custom_field_names.include?(name)
            number = (name.match(/\d+$/) || [])[0]
            name << '_1' unless number
            name.succ!
          end
          existing_custom_field_names << name

          cf.name             = name
          cf.description      = xpath['description']
          cf.easy_external_id = xpath['id']
          cf.is_for_all       = true
        end
        custom_fields.store(cf.easy_external_id.to_s, cf)
      end
      duration = duration_in_minutes(start)
      puts "Jira importer import CustomFields successfully. Duration #{duration} minutes."

      custom_field_value = {}

      @xml.xpath('//CustomFieldOption').each do |xpath|
        if (cf = custom_fields[xpath['customfield']])
          cf.possible_values += [xpath['value']]
          custom_field_value.store(xpath['id'], xpath['value'])
        end
      end

      CustomField.transaction do
        custom_fields.values.map(&:save!)
      end

      # Import custom values
      start                 = Time.now
      custom_values_to_save = []
      custom_fields.each do |id, cf|
        xml_custom_values         = @xml.xpath(%Q{//CustomFieldValue[@customfield = "#{id}"]})
        existing_custom_value_ids = CustomValue.where(easy_external_id: xml_custom_values.map { |xml| xml['id'] }).pluck(:easy_external_id)
        xml_custom_values.each do |xpath|
          if ((issue_id = get_issue_id(xpath['issue'])) && !(existing_custom_value_ids.include? xpath['id']))
            custom_values_to_save << CustomValue.new(easy_external_id: xpath['id'], custom_field_id: cf.id, customized_type: 'Issue', customized_id: issue_id, value: custom_field_value[xpath['stringvalue']] || xpath['textvalue'] || xpath['floatvalue'])
          end
        end
      end
      CustomValue.import custom_values_to_save
      duration = duration_in_minutes(start)
      puts "Jira importer import CustomValues successfully. Duration #{duration} minutes."
    end

    def import_issues(xml_issues)
      attribute_assignments       = [
          EasyEntityImportAttributesAssignment.new(source_attribute: 'summary', entity_attribute: 'subject'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'created', entity_attribute: 'created_on'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'updated', entity_attribute: 'updated_on'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'resolutiondate', entity_attribute: 'due_date'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'id', entity_attribute: 'easy_external_id')
      ]
      existing_issue_ids          = Issue.where(easy_external_id: xml_issues.map { |x| x['id'] }).pluck(:easy_external_id, :id)
      issues                      = {}
      @mapped_issues_external_ids = []
      fallback_tracker_id         = Tracker.first.id
      fallback_status_id          = IssueStatus.first.id
      fallback_priority_id        = IssuePriority.first.id
      Issue.transaction do
        xml_issues.each do |xpath|
          unless issue = create_place_holder_entity(*existing_issue_ids.find { |external_id, _| external_id == xpath['id'] })
            if (project = Project.find_by(id: @results[:projects][xpath['project']]))
              issue = project.issues.build(tracker_id: project.tracker_ids.first || fallback_tracker_id, author_id: (@results[:users] && @results[:users][xpath['creator']]) || User.current.id)
            else
              issue = Issue.new(subject: xpath['summary'])
              @logger.log_entity_error(issue, nil, "#{I18n.t('easy_imports.issue_could_not_be_created', issue_name: xpath['summary'])} #{I18n.t('easy_imports.no_project_for_task')}")
              raise ArgumentError.new('No project for task ')
            end
            description       = xpath['description'].presence || xpath.xpath('description').text.presence
            issue.description = ensure_mysql_valid_string(description) if description

            issue.assigned_to_id = get_user_id(xpath['assignee'])
            issue.priority_id    = @results[:issue_priorities][xpath['priority']].presence || fallback_priority_id
            issue.tracker_id     = @results[:trackers][xpath['type']].presence || fallback_tracker_id
            issue.status_id      = @results[:issue_statuses][xpath['status']].presence || fallback_status_id

            assign_attribute_for(issue, attribute_assignments, xpath)
            issue.subject = xpath.xpath('summary').text if issue.subject.blank?

            issue.save!(validate: false)
            @logger.log_entity_creation issue
          else
            @mapped_issues_external_ids << issue.easy_external_id
          end
          issues.store(issue.easy_external_id, issue.id)
        end
      end

      import_issues_second_iteration(xml_issues, issues)

      issues
    end

    def import_journals(xml_journals)
      mapped_issues = @mapped_issues_external_ids || [] # Journal does not have external_id

      journal_count_before_import = Journal.count
      journals_to_save            = []
      xml_journals.each do |xpath|
        next if mapped_issues.include? xpath['issue']

        unless (issue_id = get_issue_id(xpath['issue']))
          puts "Could not import Journal id: #{xpath['id']} - Task with original id '#{xpath['issue']}' not found"
          next
        end

        unless (author_id = get_user_id(xpath['updateauthor']))
          puts "Warning: Could not find user: '#{xpath['updateauthor']}' => author of journal with original_id: #{xpath['id']} will be set to current user"
        end

        notes = xpath['body'] || xpath.xpath('body').text.presence
        begin
          ; date = Time.parse(xpath['created']) rescue nil;
        end
        journal                = Journal.new(journalized_type: 'Issue', user_id: author_id || User.current.id, notes: notes, created_on: date)
        journal.journalized_id = issue_id
        journals_to_save << journal
      end

      Journal.import journals_to_save, batch_size: 1000

      imported_journals_count = Journal.count - journal_count_before_import
      not_imported_journals   = journals_to_save.size - imported_journals_count
      put "#{not_imported_journals} journals could not be imported." if (not_imported_journals) > 0
      imported_journals_count > 0 ? imported_journals_count : nil
    end

    def import_projects(xml_projects)
      attribute_assignments = [
          EasyEntityImportAttributesAssignment.new(source_attribute: 'name', entity_attribute: 'name'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'description', entity_attribute: 'description'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'key', entity_attribute: 'identifier'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'id', entity_attribute: 'easy_external_id')
      ]
      projects              = {}
      Project.transaction do
        xml_projects.each do |xpath|
          unless (project = Project.find_by(easy_external_id: xpath['id']))
            # project = template ? Project.copy_from(template) : Project.new(author_id: User.current.id) # TODO: template??
            project = Project.new(author_id: User.current.id)
            project.enable_module!('easy_wbs')
            assign_attribute_for(project, attribute_assignments, xpath)
            project.tracker_ids = @results[:trackers].values.flatten

            begin
              warnings = (project.errors.full_messages) unless project.valid?
              raise unless EasyLicenseManager.has_license_limit?(:active_project_limit)
              project.save!(validate: false)
              project.init_overview_page
              @logger.log_entity_creation project
              @logger.log_entity_warning(project, nil, warnings) if warnings.present?
            rescue
              @logger.log_entity_error(project, project.name, "#{I18n.t('easy_imports.project_could_not_be_created', project_name: project.name)}<ul>#{project.errors.full_messages.map { |m| "<li>#{m}</li>" }.join}</ul>".html_safe)
              project = nil
            end
          else
            @logger.log_entity_mapping project
          end
          projects.store(project.easy_external_id, project.id) if project && !project.new_record?
        end
      end

      projects
    end

    def import_users(xml_users)
      attribute_assignments = [
          EasyEntityImportAttributesAssignment.new(source_attribute: 'emailAddress', entity_attribute: 'mail'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'id', entity_attribute: 'easy_external_id')
      ]
      users                 = {}
      t                     = User.arel_table
      User.transaction do
        xml_users.each do |xpath|
          if (user = User.where(t[:easy_external_id].eq(xpath['id']).or(t[:easy_external_id].eq(nil).and(t[:login].eq(xpath['userName'])))).first)
            user.update_column(:easy_external_id, xpath['id']) if user.easy_external_id.blank?
            @logger.log_entity_mapping user
          else
            user = User.new
            assign_attribute_for(user, attribute_assignments, xpath)
            first_name, last_name = extract_user_first_and_last_name(xpath)
            user.firstname        = first_name.truncate(30)
            user.lastname         = last_name.truncate(30)
            user.login            = convert_jira_login_to_easy_login(xpath['userName'])
            user.status           = User::STATUS_LOCKED unless xpath['active'] != '1'
            user.password         = "#{user.login}686"
            user.save!(validate: false)
            @logger.log_entity_creation user
          end
          users.store(user.login, user.id)
        end
      end

      users
    end

    def import_groups(xml_groups)
      attribute_assignments = [
          EasyEntityImportAttributesAssignment.new(source_attribute: 'groupName', entity_attribute: 'lastname'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'id', entity_attribute: 'easy_external_id')
      ]
      groups                = {}
      t                     = Group.arel_table
      User.transaction do
        xml_groups.each do |xpath|
          if (group = Group.where(t[:easy_external_id].eq(xpath['id']).or(t[:easy_external_id].eq(nil).and(t[:lastname].eq(xpath['groupName'])))).first)
            group.update_column(:easy_external_id, xpath['id']) if group.easy_external_id.blank?
            @logger.log_entity_mapping group
          else
            group = Group.new
            assign_attribute_for(group, attribute_assignments, xpath)
            group.save!(validate: false)
            @logger.log_entity_creation group
          end
          groups.store(group.login, group.id)
        end
      end

      groups
    end

    def import_time_entries(xml_time_entries)
      attribute_assignments                = [
          EasyEntityImportAttributesAssignment.new(source_attribute: 'body', entity_attribute: 'comments'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'id', entity_attribute: 'easy_external_id'),
          EasyEntityImportAttributesAssignment.new(source_attribute: 'created', entity_attribute: 'created_on')
      ]
      jira_issue_to_our_project_id_map     = Issue.where(easy_external_id: xml_time_entries.map { |xml| xml['issue'] }).pluck(:easy_external_id, :project_id)
      existing_time_entry_ids              = TimeEntry.where(easy_external_id: xml_time_entries.map { |xml| xml['id'] }).pluck(:easy_external_id)
      default_activity_id                  = TimeEntryActivity.default.try(:id) || TimeEntryActivity.first.try(:id) || TimeEntryActivity.create(name: 'Work', is_default: true).id
      extisting_project_activity_relations = ProjectActivity.all
      imported_time_entries_count          = 0
      TimeEntry.transaction do
        xml_time_entries.each do |xpath|
          unless existing_time_entry_ids.include? xpath['id']
            time_entry = TimeEntry.new
            assign_attribute_for(time_entry, attribute_assignments, xpath)
            time_entry.project_id  = jira_issue_to_our_project_id_map.find { |jira_id, _| jira_id == xpath['issue'] }.try(:last)
            time_entry.user_id     = get_user_id(xpath['author'])
            time_entry.issue_id    = get_issue_id(xpath['issue'])
            time_entry.entity_id   = time_entry.issue_id
            time_entry.activity_id = default_activity_id

            time_entry.spent_on    = Date.parse(xpath['startdate'])
            time_entry.entity_type = 'Issue'
            time_entry.hours       = xpath['timeworked'].to_f / 3600

            unless extisting_project_activity_relations.find { |relation| relation.project_id == time_entry.project_id && relation.activity_id == time_entry.activity_id }
              if (time_entry.project_id && time_entry.activity_id)
                extisting_project_activity_relations << ProjectActivity.create(project_id: time_entry.project_id, activity_id: time_entry.activity_id)
              end
            end

            if time_entry.save
              imported_time_entries_count += 1
            else
              puts "TimeEntry #{xpath['id']} could not be imported"
            end
          end
        end
      end
      imported_time_entries_count > 0 ? imported_time_entries_count : nil
    end

    def import_trackers(xml_trackers)
      trackers       = {}
      default_status = IssueStatus.sorted.find_by(is_closed: false) || IssueStatus.sorted.first
      Tracker.transaction do
        xml_trackers.each do |xpath|
          unless (tracker = Tracker.find_by(name: xpath['name']))
            tracker                = Tracker.new(name: xpath['name'].truncate(30), position: xpath['sequence'], easy_external_id: xpath['id'])
            tracker.default_status = default_status
            tracker.save!(validate: false)
            @logger.log_entity_creation tracker
          else
            @logger.log_entity_mapping tracker
          end
          trackers.store(tracker.easy_external_id, tracker.id)
        end
      end
      trackers
    end

    def assign_attribute_for(entity, assignments, xpath)
      assignments.each do |attrs|
        entity.send("#{attrs.entity_attribute}=", xpath[attrs.source_attribute])
      end
    end

    def create_place_holder_entity(external_id = nil, id = nil)
      return nil if external_id.blank? || id.blank?
      PLACEHOLDER_STRUCT.new(external_id, id)
    end

    def ensure_mysql_valid_string(string)
      if database_encoding_utf8_unicode_ci?
        string.chars.map { |c| c.bytesize == 4 ? '' : c }.join
      else
        string
      end
    end

    def database_encoding_utf8_unicode_ci?
      @database_encoding_utf8_unicode_ci ||= Redmine::Info.database_encoding
      @database_encoding_utf8_unicode_ci == 'utf8 / utf8_unicode_ci'
    end

    def import_issues_second_iteration(xml_issues, issue_ids_map)
      Issue.transaction do
        xml_issues.each do |xpath|
          if issue = Issue.find_by(id: issue_ids_map[xpath['id']])

            created_on = Time.parse(xpath['created']) rescue nil

            args              = {}
            args[:created_on] = created_on if created_on

            issue.update_columns(args) if args.present?
          end
        end
      end
    end

    # @return [Array<String>] always returns array of 2 strings
    def extract_user_first_and_last_name(user_xpath)
      first_name = user_xpath['firstName'].presence
      last_name  = user_xpath['lastName'].presence
      if first_name.nil? || last_name.nil?
        name       = user_xpath['displayName'] || user_xpath['userName']
        name       = name.to_s.rpartition(/[\s\.\-_]/)
        last_name  ||= name.last
        first_name ||= (name.first.presence || last_name)
      end
      [first_name, last_name]
    end

    def run_imports
      import_entities('User', @xml.xpath('//User'))
      import_entities('Group', @xml.xpath('//Group'))
      import_entities('IssueStatus', @xml.xpath('//Status'))
      import_entities('IssuePriority', @xml.xpath('//Priority'))
      import_entities('Tracker', @xml.xpath('//IssueType'))
      import_entities('Project', @xml.xpath('//Project'))
      import_entities('Issue', @xml.xpath('//Issue'))
      import_entities('TimeEntry', @xml.xpath('//Worklog'))
      import_customfields
      import_attachments(File.join(File.dirname(@entities_file), 'data', 'attachments'))
      import_entities('Journal', @xml.xpath('//Action[@type = "comment"]'))
    end

  end
end
