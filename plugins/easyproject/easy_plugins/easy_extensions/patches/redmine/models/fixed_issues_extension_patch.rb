module EasyPatch
  module FixedIssuesExtensionPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :issues_progress, :easy_extensions
        alias_method_chain :estimated_average, :easy_extensions
      end
    end

    module InstanceMethods

      def estimated_average_with_easy_extensions
        if @estimated_average.nil?
          average = average("COALESCE(estimated_hours, 0)").to_f
          if average == 0
            average = 1
          end
          @estimated_average = average
        end
        @estimated_average
      end

      def issues_progress_with_easy_extensions(open)
        @issues_progress ||= {}
        @issues_progress[open] ||= begin
          progress = 0
          if count > 0
            ratio = open ? 'done_ratio' : 100

            done     = open(open).sum(Arel.sql("CASE COALESCE( estimated_hours, 0.0 ) WHEN 0 THEN #{estimated_average} ELSE estimated_hours END * #{ratio}")).to_f
            progress = done / (estimated_average * count)
          end
          progress
        end
      end

    end
  end
end

EasyExtensions::PatchManager.register_model_patch 'FixedIssuesExtension', 'EasyPatch::FixedIssuesExtensionPatch'
