module EasyGanttResources
  module EasyGanttControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        alias_method_chain :index, :easy_gantt_resources
      end
    end

    module InstanceMethods
      def index_with_easy_gantt_resources
        return index_without_easy_gantt_resources if !params[:gantt_type] || params[:gantt_type] != 'rm'

        if @project && !User.current.allowed_to?(:view_easy_gantt_resources, @project)
          return render_403
        end

        if @project.nil? && !User.current.allowed_to_globally?(:view_global_easy_gantt_resources)
          return render_403
        end

        retrieve_query
      end
    end

  end
end

EasyExtensions::PatchManager.register_controller_patch 'EasyGanttController', 'EasyGanttResources::EasyGanttControllerPatch', if: proc { Redmine::Plugin.installed?(:easy_gantt) }
