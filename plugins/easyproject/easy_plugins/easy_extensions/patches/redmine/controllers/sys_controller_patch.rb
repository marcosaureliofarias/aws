module EasyPatch
  module SysControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :projects, :easy_extensions
        alias_method_chain :fetch_changesets, :easy_extensions

        def git_fetcher
          if params[:repository_id].present? &&
              (repository = Repository.find_by(id: params[:repository_id])) &&
              repository.project&.module_enabled?('repository')

            EasyGitRepositoryFetcherJob.perform_later(repository)

            head :ok
            return
          end

          projects = if params[:project_id].present?
            Array(Project.has_module(:repository).find_by(id: params[:project_id]))
          else
            Project.active_and_planned.non_templates.sorted.has_module(:repository).preload(params[:fetch_all].present? ? :repositories : :repository).to_a
          end

          Array(projects).each do |project|
            if params[:fetch_all].present?
              project.repositories.each do |repository|
                EasyGitRepositoryFetcherJob.perform_later(repository)
              end
            elsif (repository = project.repository)
              EasyGitRepositoryFetcherJob.perform_later(repository)
            end
          end

          head :ok
        end

      end
    end

    module InstanceMethods
      # allow planned projects (for SVN)
      def projects_with_easy_extensions
        p = Project.active_and_planned.has_module(:repository).
          order("#{Project.table_name}.identifier").preload(:repository).to_a
        # extra_info attribute from repository breaks activeresource client
        render :json => p.to_json(
          :only => [:id, :identifier, :name, :is_public, :status],
          :include => {:repository => {:only => [:id, :url]}}
        )
      end

      def fetch_changesets_with_easy_extensions
        projects = []
        scope = Project.active_and_planned.has_module(:repository)
        if params[:id]
          project = nil
          if /^\d*$/.match?(params[:id].to_s)
            project = scope.find(params[:id])
          else
            project = scope.find_by_identifier(params[:id])
          end
          raise ActiveRecord::RecordNotFound unless project
          projects << project
        else
          projects = scope.to_a
        end
        projects.each do |project|
          project.repositories.each do |repository|
            repository.fetch_changesets
          end
        end
        head 200
      rescue ActiveRecord::RecordNotFound
        head 404
      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'SysController', 'EasyPatch::SysControllerPatch'
