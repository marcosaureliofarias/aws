module EasyPatch
  module MessagePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.class_eval do

        html_fragment :content, :scrub => :strip

        include EasyExtensions::EasyInlineFragmentStripper
        strip_inline_images :content
      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def easy_activity_custom_project_scope(scope, options, event_type)
        scope.where("#{Board.table_name}.project_id in (?)", options[:project_ids])
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Message', 'EasyPatch::MessagePatch'
