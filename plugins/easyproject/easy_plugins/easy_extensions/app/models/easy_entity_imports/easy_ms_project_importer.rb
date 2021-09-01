require 'easy_data_templates/ms_project/ms_project_2010_xml_parser'

module EasyEntityImports
  class EasyMsProjectImporter

    def initialize
      @logger = EasyEntityImports::ImportLogger.new
    end

    def import(params = {})
      params = parse_xml(params) if params.is_a? Tempfile

      unless params['project']
        @logger.log_fatal_error(I18n.t('easy_imports.file_could_not_be_processed'))
        return false
      end

      unless EasyLicenseManager.has_license_limit?(:active_project_limit)
        @logger.log_fatal_error(I18n.t('license_manager.project_limit'))
        return false
      end

      new_project = Project.new
      new_project.enable_module!('easy_wbs')

      new_project.safe_attributes = params['project']

      @valid_objects   ||= {}
      @invalid_objects ||= {}

      begin
        warnings = (new_project.errors.full_messages) unless new_project.valid?
        # raise StandardError unless EasyLicenseManager.has_license_limit?(:active_project_limit)
        new_project.save!(validate: false)
        new_project.set_parent!(nil)
        new_project.init_overview_page

        @valid_objects[:project] = new_project
        @logger.log_entity_creation new_project
        @logger.log_entity_warning(new_project, nil, warnings) if warnings.present?
      rescue
        @logger.log_entity_error(new_project, new_project.name, "#{I18n.t('easy_imports.project_could_not_be_created', project_name: new_project.name)}<ul>#{new_project.errors.full_messages.map { |m| "<li>#{m}</li>" }.join}</ul>".html_safe)
        @invalid_objects[:project] = new_project
        return true
      end

      # We're going to keep track of new issue ID's to make dependencies work later
      uid_to_issue_id = {}
      # keep track of new Version ID's
      uid_to_version_id = {}
      # keep track of the outlineNumbers to set the parent_id
      outlinenumber_to_issue_id   = {}
      outlinenumber_to_version_id = {}

      project_users = []

      # VERSIONS
      if params['version']
        @valid_objects[:version]   ||= {}
        @invalid_objects[:version] ||= {}
        params['version'].each do |version_uuid, version_params|
          next if version_params['allow_import'] == 'no'

          version_options = version_params.dup
          version_options.delete('allow_import')
          version_options.delete('id')

          if version_params['id']
            new_version = new_project.versions.find(version_params['id'])
          else
            new_version = new_project.versions.build
          end

          new_version.safe_attributes = version_options

          if new_version.save
            @valid_objects[:version][version_uuid.to_i] = new_version
            # Store the version_record.id to assign the issues to the version later
            uid_to_version_id[version_params['uid']]                     = new_version.id
            outlinenumber_to_version_id[version_params['outlinenumber']] = new_version.id
            @logger.log_entity_creation new_version
          else
            @invalid_objects[:version][version_uuid.to_i] = new_version
            @logger.log_entity_error(new_version, new_version.name, I18n.t('easy_imports.project_could_not_be_created', project_name: new_version.name))
          end
        end
      end

      # ISSUES
      if params['issue']
        @valid_objects[:issue]   = {}
        @invalid_objects[:issue] = {}
        params['issue'].each do |issue_uuid, issue_params|
          next if issue_params['allow_import'] == 'no'

          issue_options = issue_params.dup
          issue_options.delete('allow_import')
          issue_options.delete('id')

          issue_tracker = Tracker.find_by(id: issue_options['tracker_id'])
          if issue_tracker
            new_project.trackers << issue_tracker unless new_project.trackers.pluck(:id).include?(issue_options['tracker_id'].to_i)
          end

          if issue_params['id']
            new_issue = new_project.issues.find_by(id: issue_params['id']) || new_project.issues.build
          else
            new_issue = new_project.issues.build
          end

          new_issue.safe_attributes  = issue_options
          new_issue.fixed_version_id = uid_to_version_id[params['issue_version_relations'][issue_params['uid']]]
          new_issue.author           = User.current if new_issue.author.nil?

          project_users << new_issue.assigned_to unless project_users.include?(new_issue.assigned_to)

          Mailer.with_deliveries(false) do
            if new_issue.save
              @valid_objects[:issue][issue_uuid.to_i] = new_issue

              # Now that we know this issue's Redmine issue ID, save it off for later
              uid_to_issue_id[issue_params['uid']] = new_issue.id

              #Save the Issue's ID with the outlineNumber as an index, to set the parent_id later
              outlinenumber_to_issue_id[issue_params['outlinenumber']] = new_issue.id
              @logger.log_entity_creation new_issue
            else
              @invalid_objects[:issue][issue_uuid.to_i] = new_issue
              @logger.log_entity_error(new_issue, new_issue.project.id, "#{I18n.t('easy_imports.issue_could_not_be_created', new_issue.subject)}<ul>#{new_issue.errors.full_messages.map { |m| "<li>#{m}</li>" }.join}</ul>".html_safe)
            end
          end
        end
      end

      # RELATIONS
      if params['issue_relations']
        params['issue_relations'].each do |issue_uuid, issue_params|
          issue_from = @valid_objects[:issue][issue_uuid.to_i]
          next if issue_from.nil?

          if issue_params['relation'] && issue_params['relation']['issue_to_id']
            [issue_params['relation']['issue_to_id']].flatten.each do |issue_to_uuid|
              issue_to = @valid_objects[:issue][issue_to_uuid.to_i]
              next if issue_to.nil?
              if !IssueRelation.where(issue_from_id: issue_from.id, issue_to_id: issue_to.id).exists?
                begin
                  IssueRelation.create(relation_type: issue_params['relation']['relation_type'], delay: issue_params['relation']['delay'], issue_from: issue_from, issue_to: issue_to)
                rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid => e
                  Rails.logger.info("[WARNING] #{e}")
                end
              end
            end
          end

        end
      end

      # PREPARE ISSUES INFO
      issues_info = params['issue'].map do |issue|
        result                  = {}
        result['uid']           = issue[1]['uid']
        result['predecessors']  = issue[1]['predecessors']
        result['outlinenumber'] = issue[1]['outlinenumber']

        result
      end

      map_subtasks_and_parents(issues_info, new_project.id, nil, uid_to_issue_id, outlinenumber_to_issue_id)
      map_versions(issues_info, new_project.id, nil, uid_to_issue_id, outlinenumber_to_version_id)

    end

    def parse_xml(file_path)
      parser = nil
      begin
        parser = EasyDataTemplates::MsProject::MsProject2010XmlParser.new(file_path)
      rescue
        return {}
      end
      @xml_project = parser.project

      begin
        prepare_import_data
      rescue
        return {}
      end
    end

    def log
      @logger && @logger.log
    end

    private

    def prepare_import_data
      result = {}

      default_issue_status_id   = Tracker.order(:position).limit(1).pluck(:default_status_id).first
      default_tracker_id        = Tracker.order(:position).limit(1).pluck(:id).first
      default_issue_priority_id = IssuePriority.default.try(:id)
      # maximum_version_validator = Version.validators_on(:name).detect { |v| v.is_a?(ActiveModel::Validations::LengthValidator) }

      project           = { 'name' => @xml_project.title, 'due_date' => @xml_project.finish_date }
      result['project'] = project

      version                 = {}
      issue_version_relations = {}

      @xml_project.versions.each do |milestone|
        attributes                   = {}
        attributes['uid']            = milestone.uid
        attributes['outlinenumber']  = milestone.outlinenumber
        attributes['status']         = 'open'
        attributes['sharing']        = 'none'
        attributes['allow_import']   = 'yes'
        attributes['name']           = milestone.name
        attributes['effective_date'] = milestone.finish_date

        if milestone.predecessor_links && milestone.predecessor_links.size > 0
          milestone.predecessor_links.each do |predecessor_link|
            if predecessor_link.predecessor_uid && (related_task = @xml_project.tasks_by_uid(predecessor_link.predecessor_uid))
              issue_version_relations[related_task.uid] = milestone.uid
            end
          end
        end

        version[milestone.uid] = attributes
      end
      result['issue_version_relations'] = issue_version_relations
      result['version']                 = version

      issues          = {}
      issue_relations = {}

      @xml_project.tasks.each do |issue|
        next if issue.name.blank? || issue.milestone == 1
        attributes                    = {}
        attributes['uid']             = issue.uid
        attributes['outlinenumber']   = issue.outlinenumber
        attributes['allow_import']    = 'yes'
        attributes['subject']         = issue.name
        attributes['description']     = issue.notes
        attributes['tracker_id']      = default_tracker_id #TODO: tracker mapping ?
        attributes['assigned_to_id']  = nil # User.active.easy_type_internal.first.id #TODO: user mapping !!
        attributes['priority_id']     = default_issue_priority_id #TODO: priority mapping ?
        attributes['status_id']       = default_issue_status_id #TODO: status mapping ?
        attributes['start_date']      = issue.start_date
        attributes['due_date']        = issue.finish_date
        attributes['done_ratio']      = (issue.percent_complete || 0) / 10 * 10
        attributes['estimated_hours'] = msproject_work_to_estimated_hours(issue.work)

        if issue.predecessor_links && issue.predecessor_links.size > 0
          issue.predecessor_links.each do |predecessor_link|
            if predecessor_link.predecessor_uid && (related_task = @xml_project.tasks_by_uid(predecessor_link.predecessor_uid))
              issue_relations[issue.uid]             = {}
              issue_relations[issue.uid]['relation'] = {}

              attributes['predecessors']                               = related_task.uid
              issue_relations[issue.uid]['relation']['issue_to_id']    = [related_task.uid]
              issue_relations[issue.uid]['relation']['relation_type']  = 'follows'
              issue_relations[issue.uid]['relation']['relation_delay'] = '0'

            end
          end
        end

        #TODO: custom fields

        issues[issue.uid] = attributes
      end
      result['issue']           = issues
      result['issue_relations'] = issue_relations

      result
    end

    # def errors?
    #   !@invalid_objects[:project].blank? || !@invalid_objects[:issue].blank? || !@invalid_objects[:user].blank? || !@invalid_objects[:version].blank?
    # end

    # def error_message
    #   return "#{I18n.t('field_project')}: " + @invalid_objects[:project].errors.full_messages.join(', ') if @invalid_objects[:project].present?
    #   return "#{I18n.t('field_user')}: " + @invalid_objects[:user].values.first.join(', ') if @invalid_objects[:user].present?
    #   [:issue, :version].each do |type|
    #     if @invalid_objects[type].present? && (invalid_object = @invalid_objects[type].values.first)
    #       return "#{I18n.t("field_#{type}")}: " + invalid_object.errors.full_messages.join(', ')
    #     end
    #   end
    # end

    def map_subtasks_and_parents(tasks, project_id, hashed_name = nil, uid_to_issue_id = nil, outlinenumber_to_issue_id = nil)
      Rails.logger.info "DEBUG: #{__method__.to_s} started"
      Rails.logger.info "tasks: #{tasks.try(:size)}, hashed_name: #{hashed_name}, project: #{project_id}"

      Issue.transaction do
        tasks.each do |source_issue|
          parent_outlinenumber = source_issue['outlinenumber'].split('.')[0...-1].join('.')
          Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
          if parent_outlinenumber.present?
            if destination_issue = Issue.find_by_id_and_project_id(uid_to_issue_id[source_issue['uid']], project_id)
              Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
              unless outlinenumber_to_issue_id[parent_outlinenumber].nil?
                Rails.logger.info "DEBUG: SET Parent id to #{destination_issue.id} -> #{outlinenumber_to_issue_id[parent_outlinenumber]}"
                # Rails.logger.info "[MAP SUBTASK] Parent ID #{outlinenumber_to_issue_id[parent_outlinenumber]} : #{Issue.find(outlinenumber_to_issue_id[parent_outlinenumber])} outline -> #{parent_outlinenumber}"
                destination_issue.update_attributes(parent_issue_id: outlinenumber_to_issue_id[parent_outlinenumber])
              end
            end
          end
        end
      end
    end

    def map_versions(tasks, project_id, hashed_name = nil, uid_to_issue_id = nil, outlinenumber_to_version_id = nil)
      Rails.logger.info "DEBUG: #{__method__.to_s} started"
      Rails.logger.info "tasks: #{tasks.try(:size)}, hashed_name: #{hashed_name}, project: #{project_id}"

      Issue.transaction do
        tasks.each do |source_issue|
          parent_outlinenumber = source_issue['outlinenumber'].split('.')[0...-1].join('.')
          Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
          if parent_outlinenumber.present?
            if destination_issue = Issue.find_by_id_and_project_id(uid_to_issue_id[source_issue['uid']], project_id)
              Rails.logger.info "[MAP SUBTASK] Issue uid #{source_issue} outline -> #{parent_outlinenumber}"
              unless outlinenumber_to_version_id[parent_outlinenumber].nil?
                Rails.logger.info "DEBUG: SET Version id to #{destination_issue.id} -> #{outlinenumber_to_version_id[parent_outlinenumber]}"
                # Rails.logger.info "[MAP SUBTASK] Version ID #{outlinenumber_to_version_id[parent_outlinenumber]} : #{Version.find(outlinenumber_to_version_id[parent_outlinenumber])} outline -> #{parent_outlinenumber}"
                destination_issue.update_attributes(fixed_version_id: outlinenumber_to_version_id[parent_outlinenumber])
              end
            end
          end
        end
      end
    end

    # TODO: remove duplicity, is already defined in helper
    def msproject_work_to_estimated_hours(work)
      return nil if work.to_s.blank?
      m = work.match(/^PT(\d+)H(\d+)M(\d+)S$/)
      return nil unless m
      (m[1].to_i + m[2].to_i / 60 + m[3].to_i / 3600)
    end
  end
end
