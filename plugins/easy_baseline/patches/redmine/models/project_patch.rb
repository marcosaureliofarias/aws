module EasyBaseline
  module ProjectPatch

    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods

      base.class_eval do
        belongs_to :easy_baseline_for, class_name: 'Project'
        has_many :easy_baseline_sources, foreign_key: 'baseline_id', dependent: :destroy
        has_many :easy_baselines, class_name: 'Project', foreign_key: 'easy_baseline_for_id', dependent: :destroy

        before_save :prevent_unarchive_easy_baseline

        alias_method_chain :copy_versions, :easy_baseline
        alias_method_chain :allows_to?, :easy_baseline
        alias_method_chain :validate_parent, :easy_baseline
        alias_method_chain :validate_custom_field_values, :easy_baseline

        scope :no_baselines, proc {
          where(easy_baseline_for_id: nil).where.not(identifier: EasyBaseline::IDENTIFIER)
        }

        class << self
          alias_method_chain :allowed_to_condition, :easy_baseline
          alias_method_chain :next_identifier, :easy_baseline
        end
      end
    end

    module InstanceMethods

      def baseline_root?
        identifier == EasyBaseline::IDENTIFIER
      end

      def copy_versions_with_easy_baseline(project)
        copy_versions_without_easy_baseline(project)
        if self.easy_baseline_for_id == project.id
          self.versions.each do |v|
            v.copied_from = project.versions.detect{|cv| cv.name == v.name}
            v.save
          end
        end
      end

      def allows_to_with_easy_baseline?(action)
        return true if easy_baseline_for_id && archived?

        allows_to_without_easy_baseline?(action)
      end

      def validate_custom_field_values_with_easy_baseline
        if self.baseline_root? && self.archived?
          true
        else
          validate_custom_field_values_without_easy_baseline
        end
      end

      def create_baseline_from_project(options = {})
        baseline = Project.copy_from(self)
        baseline.status = Project::STATUS_ARCHIVED
        # Without this hack it disables a modules on original project see http://www.redmine.org/issues/20512 for details
        baseline.enabled_modules = []
        baseline.enabled_module_names = self.enabled_module_names
        baseline.name =  options[:name] || "#{format_time(Time.now)} #{self.name}"
        baseline.identifier = options[:name].present? ? options[:name].parameterize : "#{self.identifier}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
        baseline.easy_baseline_for_id = self.id
        baseline.parent = EasyBaseline.baseline_root_project
        # Project.copy_from change customized so CV are not copyied but moved
        # Already done in easyredmine
        baseline.custom_values = self.custom_values.map{ |v|
          cloned_v = v.dup
          cloned_v.customized = baseline
          cloned_v
        }
        baseline
      end

      private

        def validate_parent_with_easy_baseline
          if @unallowed_parent_id
            errors.add(:parent_id, :invalid)
          elsif parent_id_changed?
            if parent.present? && (!parent.active? || !move_possible?(parent)) && !parent.baseline_root?
              errors.add(:parent_id, :invalid)
            end
          end
        end

        def prevent_unarchive_easy_baseline
          if (easy_baseline_for_id || baseline_root?) && status_changed? && !archived?
            errors.add(:status, :invalid)
            return false
          end
        end

    end

    module ClassMethods

      def allowed_to_condition_with_easy_baseline(user, permission, options={}, &block)
        condition = allowed_to_condition_without_easy_baseline(user, permission, options, &block)

        if options[:easy_baseline].present?
          condition.gsub!("#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND", "")
        end
        condition
      end

      def next_identifier_with_easy_baseline
        p = Project.where.not(identifier: EasyBaseline::IDENTIFIER).where(easy_baseline_for_id: nil).order('id DESC').first
        p.nil? ? nil : p.identifier.to_s.succ
      end

    end
  end
end
RedmineExtensions::PatchManager.register_model_patch 'Project', 'EasyBaseline::ProjectPatch'
