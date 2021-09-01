module RedmineRe
  class CopyToProject < ::EasyExtensions::BaseService
    attr_reader :source_project, :target_project, :issues_map, :re_artifact_properties_mapper

    def initialize(source_project:, target_project:, options:)
      @source_project = source_project
      @target_project = target_project
      @issues_map     = options[:issues_map] || {}
      @re_artifact_properties_mapper  = {}
    end

    def call
      copy_re_settings

      copy_re_queries

      copy_re_statuses

      copy_re_artifact_properties

      copy_dependencies
    end

    private

    def re_artifact_properties_ordered
      root_node = source_project.re_artifact_properties.find_by(artifact_type: 'Project')

      return [] if root_node.nil?

      [root_node] + root_node.gather_children
    end

    def copy_re_artifact_properties
      re_artifact_properties_ordered.each do |re_artifact_property|
        new_re_artifact_property = re_artifact_property.dup
        new_re_artifact_property.project   = target_project
        new_re_artifact_property.parent    = re_artifact_properties_mapper[re_artifact_property.parent_id]
        new_re_artifact_property.re_status = target_project.re_statuses.find_by(label: re_artifact_property.re_status&.label)
        new_re_artifact_property.save

        re_artifact_properties_mapper[re_artifact_property.id] = new_re_artifact_property
      end
    end

    def copy_dependencies
      source_project.re_artifact_properties.each do |re_artifact_property|
        new_re_artifact_property = re_artifact_properties_mapper[re_artifact_property.id]

        re_artifact_property.dependency_relations.each do |dependency_relation|
          new_dependency = re_artifact_properties_mapper[dependency_relation.sink_id]

          new_re_artifact_property.dependency_relations.create(sink: new_dependency)
        end

        re_artifact_property.conflict_relations.each do |conflict_relation|
          new_conflict = re_artifact_properties_mapper[conflict_relation.sink_id]

          new_re_artifact_property.conflict_relations.create(sink: new_conflict)
        end

        re_artifact_property.issues.each do |issue|
          new_issue = issues_map[issue.id]
          new_issue = issue if new_issue.nil?

          new_re_artifact_property.re_realizations.create(issue_id: new_issue.id)
        end

        re_artifact_property.attachments.each do |attachment|
          new_attachment = attachment.copy
          new_attachment.container_id = new_re_artifact_property.id
          new_attachment.save
        end

        new_re_artifact_property.save
      end
    end

    def copy_re_settings
      source_project.re_settings.each do |re_setting|
        new_re_setting = re_setting.dup
        new_re_setting.project = target_project
        new_re_setting.save
      end
    end

    def copy_re_queries
      source_project.re_queries.each do |re_query|
        new_re_query = re_query.dup
        new_re_query.name = "#{new_re_query.name} - #{target_project.name}"
        new_re_query.project = target_project
        new_re_query.save
      end
    end

    def copy_re_statuses
      source_project.re_statuses.each do |re_status|
        new_re_status = re_status.dup
        new_re_status.project = target_project
        new_re_status.save
      end
    end
  end
end