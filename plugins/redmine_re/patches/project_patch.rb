module RedmineRe
  module ProjectPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do
        has_many :re_artifact_properties, :dependent => :destroy, :class_name => "ReArtifactProperties"
        has_many :re_settings, :dependent => :destroy
        has_many :re_queries, :dependent => :destroy
        has_many :re_statuses, dependent: :destroy
        has_one  :requirements_hierarchy, -> { where(name: 'project_hierarchy') }, class_name: 'ReSetting'

        delegate :value, to: :requirements_hierarchy, prefix: true, allow_nil: true

        scope :with_requirements_hierarchy_type, ->(type) { visible.joins(:requirements_hierarchy).where(re_settings: { value: type }) }
      end
    end

    module InstanceMethods
      def copy_requirements(project, options = {})
        RedmineRe::CopyToProject.call(source_project: project, target_project: self, options: options)
      end
    end

    module ClassMethods
      def in_requirements_hierarchy_of(project)
        where(id: requirements_hierarchy_of(project) + [project]).
        where(id: with_requirements_hierarchy_of(project))
      end

      def requirements_hierarchy_of(project)
        case project.requirements_hierarchy_value.to_s.to_sym
        when :hierarchy
          project.hierarchy.visible
        when :descendants
          project.self_and_descendants.visible
        when :all
          visible
        else
          Project.none
        end
      end

      def with_requirements_hierarchy_of(project)
        ids = with_requirements_hierarchy_type('all').pluck(:id) +
              project.hierarchy.where(id: with_requirements_hierarchy_type('hierarchy')).pluck(:id) +
              project.ancestors.where(id: with_requirements_hierarchy_type('descendants')).pluck(:id)

        where(id: ids + [project.id])
      end
    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'Project', 'RedmineRe::ProjectPatch'
