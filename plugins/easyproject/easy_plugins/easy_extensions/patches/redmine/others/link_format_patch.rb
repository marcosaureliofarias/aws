module EasyPatch
  module LinkFormatPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        self.searchable_supported = true

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::LinkFormat', 'EasyPatch::LinkFormatPatch'
