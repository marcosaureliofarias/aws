module EasyPatch
  module WorkflowsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def workflow_options
          return @workflow_options if @workflow_options

          @workflow_options = [
              [l(:general_text_Yes), "1"],
              [l(:general_text_No), "0"],
              [l(:label_no_change_option), "no_change"]
          ]
        end

        def workflow_options_json
          workflow_options.collect { |o| { text: o[0], value: o[1] } }.to_json
        end
      end
    end

    module InstanceMethods


    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'WorkflowsHelper', 'EasyPatch::WorkflowsHelperPatch'
