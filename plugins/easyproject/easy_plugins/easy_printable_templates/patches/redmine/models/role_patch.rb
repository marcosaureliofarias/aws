module EasyPrintableTemplates
  module RolePatch

    def self.included(base)
      base.class_eval do

        const_set(:EASY_PRINTABLE_TEMPLATES_VISIBILITY_OPTIONS, [
            ['all', :label_easy_printable_templates_visibility_all],
            ['own', :label_easy_printable_templates_visibility_own]
        ])

        validates_inclusion_of :easy_printable_templates_visibility,
                               in: Role::EASY_PRINTABLE_TEMPLATES_VISIBILITY_OPTIONS.collect(&:first),
                               if: lambda {|role| role.respond_to?(:easy_printable_templates_visibility) && role.easy_printable_templates_visibility_changed?}

        safe_attributes 'easy_printable_templates_visibility'

      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Role', 'EasyPrintableTemplates::RolePatch'
