module EasyPatch
  module IssueCategoryPatch

    def self.included(base)
      base.include(Redmine::NestedSet::Traversing)

      base.class_eval do
        scope :like, ->(arg) {
          if arg.present?
            pattern = "%#{arg.to_s.strip}%"
            where(Redmine::Database.like("#{table_name}.name", ':p'), { p: pattern })
          end
        }

        safe_attributes 'parent_id'
        acts_as_nested_set :order => 'name', :dependent => :destroy, :scope => 'project_id'
      end
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'IssueCategory', 'EasyPatch::IssueCategoryPatch'
