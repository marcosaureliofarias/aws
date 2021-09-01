module EasyPatch
  module RepositoriesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        include EasySettingHelper

        before_action :repo_save_easy_settings, :only => [:create, :update]
        before_action :create_repo_from_url, :only => [:create]
        after_action :delete_repository, :only => [:destroy]

        def repo_save_easy_settings
          save_easy_settings(@project)
        end

        def create_repo_from_url
          return if params[:easy_repository_source] != 'easy_repository_url' || params[:repository].blank? || params[:repository][:easy_repository_url].blank?
          repo_url = params[:repository][:easy_repository_url]

          repo_container_dir = File.absolute_path(File.join(Rails.root, EasySetting.value('git_repository_path')))

          begin
            FileUtils.mkdir(repo_container_dir) unless File.exist?(repo_container_dir)
          rescue StandardError => ex
            flash[:error] = ex.message
          end

          unless File.exist?(repo_container_dir)
            flash[:error] = l(:error_create_repo_from_url_cannot_create_dir, :dir => repo_container_dir)
            return
          end

          if (m = (repo_url.match(/^\S*\/(\S+.git)$/) || repo_url.match(/^\S*\/(\S+.)$/)))
            repo_name = m[1]
          end

          if repo_name.blank?
            flash[:error] = l(:error_create_repo_from_url_cannot_determine_repo_name)
            return
          end

          begin
            repository_url              = @repository.scm.ensure!(repo_url, repo_name)
            @repository.safe_attributes = { url: repository_url }
          rescue Redmine::Scm::Adapters::CommandFailed => e
            flash[:error] = (l(:error_create_repo_from_url_repo_cannot_be_created) + '<br>' + e.message).html_safe
            return false
          end

        end

      end
    end

    def delete_repository
      return if Repository.where(id: @repository).exists?

      if (m = (@repository.url.match(/^.*\/(.+.git)$/) || @repository.url.match(/^.*\/(.+.)$/)))
        repo_name = m[1]
      end

      if repo_name.blank?
        flash[:error] = l(:error_create_repo_from_url_cannot_determine_repo_name)
        return
      end

      repo_container_dir = File.absolute_path(File.join(Rails.root, EasySetting.value('git_repository_path')))
      repository_path    = File.join repo_container_dir, repo_name

      FileUtils.rm_rf repository_path
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'RepositoriesController', 'EasyPatch::RepositoriesControllerPatch'
