module EasyAgileBoard
  module EasyQueriesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      
      base.class_eval do
        alias_method_chain :output_data, :easy_agile_board
      end
    end

    module InstanceMethods
      def output_data_with_easy_agile_board
        if params[:easy_sprint_id] && (sprint = EasySprint.find_by(id: params[:easy_sprint_id]))
          @easy_query.dont_use_project = sprint.cross_project?
          @easy_query.project = nil if @easy_query.dont_use_project
        end
        output_data_without_easy_agile_board
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'EasyQueriesController', 'EasyAgileBoard::EasyQueriesControllerPatch'
