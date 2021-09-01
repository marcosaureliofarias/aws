module RedmineRe
  module IssueControllerPatch

   # require_dependency 'issues_controller'

  #Mixin for Issue Controller

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :update_issue_from_params, :artifacts
        alias_method_chain :create, :artifacts
        alias_method_chain :new, :artifacts
      end
    end

    module InstanceMethods
      def update_issue_from_params_with_artifacts
        if params[:issue].present? && params[:artifact_id].present?
          @issue.re_artifact_properties = ReArtifactProperties.where(id: params[:artifact_id])
        end

        update_issue_from_params_without_artifacts
      end

      def create_with_artifacts
        create_without_artifacts
        unless params[:artifact_id].blank?
          params[:artifact_id].each do |aid|
            @issue.re_artifact_properties << ReArtifactProperties.find(aid)
          end
        end
      end

      def new_with_artifacts
        @insertvalues = {"artifacttype" => params[:artifacttype], "artifactname"=>params[:artifactname], "artifactid"=>params[:artifactid]}
        new_without_artifacts
      end

    end
  end
end

RedmineExtensions::PatchManager.register_controller_patch 'IssuesController', 'RedmineRe::IssueControllerPatch'
