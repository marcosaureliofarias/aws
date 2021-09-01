module EasyXmlData
  class Exporter
    require 'zip'

    def initialize(exportables, project_ids)
      @project_ids = project_ids
      @projects = Project.preload(project_preload_list).where(:id => project_ids)
      @exportables = exportables
      @redmine_plugins = Redmine::Plugin.all(:without_disabled => true).collect(&:id)

      collect_entities
      set_default_metadata
    end

    def project_preload_list
      list = [
        :time_entries,
        :trackers,
        :roles,
        { memberships: [:roles] },
        { news: [:comments] },
        :project_activity_roles,
        :enabled_modules,
        { documents: [{ attachments: :versions }] }
      ]
      Redmine::Hook.call_hook(:easy_xml_data_exporter_project_preload_list, {:list => list})
      return list
    end

    def issue_preload_list
      list = [
        { attachments: :versions },
        { journals: [:details, :user] },
        :author,
        :assigned_to,
        :status,
        :tracker,
        :custom_values,
        :relations_from,
        :relations_to
      ]
      Redmine::Hook.call_hook(:easy_xml_data_exporter_issue_preload_list, {:list => list})
      return list
    end

    def self.exportables
      @exportables ||= [:issues, :news, :documents, :time_entries, :attachments, :wikis]
    end

    def self.exportable_labels
      @exportable_labels ||= Hash.new
    end

    def export_dir
      File.join(Attachment.storage_path, 'easy_xml_data_export_data', User.current.id.to_s)
    end

    def metadata_xml_file_path
      File.join(export_dir, 'metadata.xml')
    end

    def data_xml_file_path
      File.join(export_dir, 'data.xml')
    end

    def archive_file_path
      File.join(export_dir, 'archive.zip')
    end

    def clear_files
      export_dir = self.export_dir
      if File.exists? export_dir
        Dir["#{export_dir}/*"].each{ |file| FileUtils.rm_r(file) }
      else
        FileUtils.mkdir_p(export_dir)
      end
    end

    def prepare_files
      File.open(metadata_xml_file_path, 'w+') do |df|
        builder = Builder::XmlMarkup.new(target: df, indent: 4)
        builder.instruct!
        @metadata.to_xml(builder: builder, skip_instruct: true, root: :metadata)
      end
      File.open(data_xml_file_path, 'w+') do |df|
        builder = Builder::XmlMarkup.new(:target => df, :indent => 4)
        builder.instruct!
        build_xml(builder)
      end
    end

    def build_archive
      clear_files
      prepare_files
      Zip::File.open(archive_file_path, Zip::File::CREATE) do |zip|
        zip.add('data.xml', data_xml_file_path)
        zip.add('metadata.xml', metadata_xml_file_path)
        @attachment_versions.uniq { |version| version.diskfile }.each do |version|
          diskfile = version.diskfile
          disk_directory = version.disk_directory
          disk_filename = version.disk_filename
          zip.add("attachments/#{disk_directory}/#{disk_filename}", diskfile) if File.exists?(diskfile)
        end if @attachment_versions.present?
      end
      archive_file_path
    end

    def build_xml(bob)
      bob.easy_xml_data do
        @users.present? && @users.to_xml(
          builder: bob,
          skip_instruct: true,
          except: [:easy_user_type, :easy_zoom_user_uid],
          procs: [
            proc do |options, record|
              options[:builder].tag!('easy-user-type-id', record.easy_user_type_id)
              options[:builder].tag!('mail', record.mail)
            end
          ]
        )
        @groups.present? && @groups.to_xml(
          builder: bob,
          skip_instruct: true,
          include: { users: { only: [:id] } }
        )
        @project_custom_fields.present? && @project_custom_fields.to_xml(
          builder: bob,
          skip_instruct: true,
          except: [:settings],
          procs: [proc { |options, record| options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml') }]
        )
        @easy_project_template_custom_fields.present? && @easy_project_template_custom_fields.to_xml(
          builder: bob,
          skip_instruct: true,
          except: [:settings],
          procs: [proc { |options, record| options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml') }]
        )
        @issue_custom_fields.present? && @issue_custom_fields.to_xml(
          builder: bob,
          skip_instruct: true,
          except: [:settings],
          procs: [proc { |options, record| options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml') }]
        )
        @trackers.present? && @trackers.to_xml(
          builder: bob,
          skip_instruct: true,
          include: { custom_fields: { only: [:id] } }
        )
        @projects.present? && @projects.to_xml(
          builder: bob,
          skip_instruct: true,
          include: {
            trackers: { only: [:id] },
            enabled_modules: { only: [:name] },
            project_custom_fields: { only: [:id] },
            issue_custom_fields: { only: [:id] },
            easy_custom_project_menus: { only: [:menu_item, :name, :url, :position] },
          },
          procs: [
            proc do |options, record|
              custom_fields_ids = (@project_custom_fields + @easy_project_template_custom_fields).map(&:id)
              record.custom_values.where(custom_field_id: custom_fields_ids).to_xml(builder: options[:builder], skip_instruct: true)
            end
          ]
        )
        @easy_page_zone_modules.present? && @easy_page_zone_modules.to_xml(
          builder: bob,
          skip_instruct: true,
          except: [:uuid, :easy_pages_id, :easy_page_available_zones_id, :easy_page_available_modules_id, :settings],
          procs: [proc { |options, record| options[:builder].tag!('id', record.id) },
                  proc { |options, record| options[:builder].tag!('easy-page', record.page_definition.page_name) },
                  proc { |options, record| options[:builder].tag!('easy-page-zone', record.zone_definition.zone_name) },
                  proc { |options, record| options[:builder].tag!('easy-page-module', record.module_definition.type) },
                  proc do |options, record|
                    record.do_not_translate = true
                    options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml')
                  end]
        )
        @easy_page_user_tabs.present? && @easy_page_user_tabs.to_xml(
          builder: bob,
          skip_instruct: true,
          except: [:page_id, :settings, :name],
          procs: [proc { |options, record| options[:builder].tag!('page-id', record.entity_id ? nil : record.page_id) },
                  proc { |options, record| options[:builder].tag!('easy-page', record.entity_id ? record.page_definition.page_name : nil) },
                  proc { |options, record| options[:builder].tag!('settings', record.settings.to_yaml, type: 'yaml') },
                  proc { |options, record| options[:builder].tag!('name', record.name(translated: false)) }]
        )
        @roles.present? && @roles.to_xml(builder: bob, skip_instruct: true)
        @members.present? && @members.to_xml(
          builder: bob,
          skip_instruct: true,
          procs: [
            proc do |options, record|
              options[:builder].tag!('roles', type: 'array') do
                record.roles.where(member_roles: { inherited_from: nil }).pluck(:id).each do |role_id|
                  options[:builder].tag!('role') do
                    options[:builder].tag!('id', role_id, type: 'integer')
                  end
                end
              end
            end
          ]
        )
        @versions.present? && @versions.to_xml(builder: bob, skip_instruct: true)
        @issues.present? && @issue_priorities.to_xml(builder: bob, skip_instruct: true)
        @issue_statuses.present? && @issue_statuses.to_xml(builder: bob, skip_instruct: true)
        @issue_categories.present? && @issue_categories.to_xml(builder: bob, skip_instruct: true)
        @issues.present? && @issues.to_xml(
          builder: bob,
          skip_instruct: true,
          include: { custom_values: {} },
          except: [:easy_repeat_settings],
          procs: [proc { |options, record| options[:builder].tag!('easy-repeat-settings', record.easy_repeat_settings.to_yaml, type: 'yaml') }]
        )
        @issue_relations.present? && @issue_relations.to_xml(builder: bob, skip_instruct: true)
        @issues.present? && @journals.to_xml(builder: bob, skip_instruct: true, include: [:details])

        @workflow_rules.present? && @workflow_rules.to_xml(builder: bob, skip_instruct: true)

        @news.present? && @news.to_xml(builder: bob, skip_instruct: true)
        @comments.present? && @comments.to_xml(builder: bob, skip_instruct: true)

        @document_categories.present? && @document_categories.to_xml(builder: bob, skip_instruct: true)
        @documents.present? && @documents.to_xml(builder: bob, skip_instruct: true)

        @time_entry_activities.present? && @time_entry_activities.to_xml(
          builder: bob,
          skip_instruct: true,
          except: [:project_id, :position]
        )
        @project_activities.present? && @project_activities.to_xml(builder: bob, skip_instruct: true)
        @project_activity_roles.present? && @project_activity_roles.to_xml(builder: bob, skip_instruct: true)

        @time_entries.present? && @time_entries.to_xml(builder: bob, skip_instruct: true)

        @attachments.present? && @attachments.to_xml(builder: bob, skip_instruct: true)
        @attachment_versions.present? && @attachment_versions.to_xml(builder: bob, skip_instruct: true)
        @easy_translations.present? && @easy_translations.to_xml(
          builder: bob,
          skip_instruct: true
        )

        @wikis.present? && @wikis.to_xml(builder: bob, skip_instruct: true)
        @wiki_pages.present? && @wiki_pages.to_xml(builder: bob, skip_instruct: true)
        @wiki_contents.present? && @wiki_contents.to_xml(builder: bob, skip_instruct: true)
        @wiki_content_versions.present? && @wiki_content_versions.to_xml(builder: bob, skip_instruct: true)
        @wiki_redirects.present? && @wiki_redirects.to_xml(builder: bob, skip_instruct: true)

        Redmine::Hook.call_hook(:easy_xml_data_exporter_build_xml, builder: bob)
      end
    end

    private

    def collect_entities

      # projects and stuff
      [
        :@users,
        :@groups,
        :@trackers,
        :@roles,
        :@members,
        :@versions,
        :@project_custom_fields,
        :@issue_custom_fields,
        :@attachments,
        :@easy_project_template_custom_fields,
        :@wikis,
        :@wiki_pages,
        :@wiki_contents,
        :@wiki_content_versions,
        :@wiki_redirects
      ].each { |var| instance_variable_set(var, []) }

      @projects.each do |project|
        @users = project.users | @users
        @groups = Group.joins(:members).where(users: { type: 'Group', status: Principal::STATUS_ACTIVE }, members: { project_id: project.id }).uniq | @groups
        @trackers = project.trackers | @trackers
        @trackers = Tracker.where(id: Issue.where(project: project).select(:tracker_id)) | @trackers
        @roles = project.roles | @roles
        @members = (project.memberships.joins(:principal).where('users.type LIKE ?', '%User%').where(users: { status: Principal::STATUS_ACTIVE }).joins(:roles).where(member_roles: {inherited_from: nil}).uniq + project.memberships.joins(:principal).where('users.type LIKE ?', '%Group%')) | @members
        project.memberships.each{|r| @roles = r.roles | @roles }
        @versions = project.versions | @versions
        project_available_custom_fields = project.available_custom_fields
        @project_custom_fields = project_available_custom_fields.select { |cf| (cf.type == 'ProjectCustomField')  && !cf.easy_do_not_export } | @project_custom_fields
        @easy_project_template_custom_fields = project_available_custom_fields.select { |cf| (cf.type == 'EasyProjectTemplateCustomField') && !cf.easy_do_not_export } | @easy_project_template_custom_fields
        @issue_custom_fields = project.issue_custom_fields.select { |cf| !cf.easy_do_not_export } | @issue_custom_fields
        if @exportables.include?(:wikis) && project.wiki
          @wikis << project.wiki
          @wiki_pages = project.wiki.pages | @wiki_pages
          @wiki_contents = project.wiki.pages.collect(&:content).flatten | @wiki_contents
          @wiki_redirects = project.wiki.redirects | @wiki_redirects
        end
      end
      @issue_custom_fields = IssueCustomField.where(:is_for_all => true) | @issue_custom_fields
      @easy_page_zone_modules = EasyPageZoneModule.includes([:page_definition, :zone_definition, :module_definition]).where(:easy_pages => {:page_scope => 'project'}).where(:entity_id => @project_ids)
      @easy_page_user_tabs = EasyPageUserTab.where(entity_id: @project_ids)
      @easy_translations = @easy_page_user_tabs.map(&:easy_translations).flatten
      @wiki_content_versions = @wiki_contents.collect(&:versions).flatten

      #issues and stuff
      if @exportables.include? :issues
        @issues = []
        @issue_relations = []
        @journals = []
        @issue_statuses = []
        @issue_categories = []
        @projects.each do |project|
          project_issues = project.issues.preload(issue_preload_list)
          @issues.concat project_issues
          @issue_relations.concat project_issues.select{|i| i.relations_from.any?}.collect{|i| i.relations_from}
          @journals.concat project_issues.collect(&:journals).flatten
          @issue_statuses = project_issues.collect(&:status).flatten | @issue_statuses
          @issue_statuses = (@issue_statuses + project.trackers.map(&:default_status)).uniq
          @issue_categories = project_issues.collect(&:category).flatten | @issue_categories
        end

        @issue_priorities = IssuePriority.all

        #users from journals
        @journals.each do |j|
          u = j.user
          @users << u unless @users.include?(u)
        end

        #users from issues
        @issues.each do |issue|
          @users << issue.author unless issue.author.blank? || @users.include?(issue.author)
        end
      end

      #workflows rules
      unless @roles.blank? || @trackers.blank?
        @workflow_rules = WorkflowRule.where(:role_id => @roles, :tracker_id => @trackers)
      end

      #news
      if @exportables.include? :news
        @news = @projects.collect(&:news).flatten
        @comments = @news.collect(&:comments).flatten
        @news.each do |n|
          @users << n.author unless @users.include? n.author
        end
        @comments.each do |c|
          @users << c.author unless @users.include? c.author
        end
      end

      #documents
      if @exportables.include? :documents
        @documents = @projects.collect(&:documents).flatten
        @document_categories = @documents.collect(&:category).flatten.uniq
      end

      #activities
      @time_entry_activities = @projects.collect{|p| p.activities + p.role_activities}.flatten.uniq
      @project_activity_roles = @projects.collect(&:project_activity_roles).flatten
      @project_activities = ProjectActivity.where(:project_id => @projects)

      #time_entries
      if @exportables.include? :time_entries
        @time_entries = @projects.collect(&:time_entries).flatten
        @time_entries.each do |te|
          @users << te.user unless @users.include?(te.user)
        end
      end

      #attachments
      @attachments, @attachment_versions = Array.new(2) { [] }
      if @exportables.include? :attachments
        Array(@issues).each { |i| @attachments.concat i.attachments }
        Array(@documents).each { |i| @attachments.concat i.attachments }
        @users = @users | User.where(id: @attachments.map(&:author_id)).to_a

        @attachment_versions = @attachments.collect(&:versions).flatten
      end

      #easy_money
      Redmine::Hook.call_hook(:easy_xml_data_exporter_collect_entities, {:exporter => self})

    end

    def set_default_metadata
      if @projects.length == 1
        project = @projects.first
        @metadata = { entity_type: project.easy_is_easy_template ? 'ProjectTemplate': Project.to_s }
        @metadata.merge!(name: project.name, description: project.description)
      else
        @metadata = { entity_type: Project.to_s, entity_count: @projects.length }
      end
    end

  end
end
