module EasyAgileBoard
  module ApplicationHelperPatch

    def self.included(base)
      base.class_eval do

        def url_to_easy_sprint(easy_sprint, options={})
          project_easy_sprint_url(easy_sprint.project_id || options[:project], easy_sprint, url_standard_options(options))
        end

        def link_to_easy_sprint(easy_sprint, options = {})
          link_to easy_sprint.to_s, project_easy_sprint_path(easy_sprint.project_id || options[:project], easy_sprint), options
        end

        def include_easy_agile_board_headers_tags(project, easy_sprint)
          unless @easy_agile_board_headers_tags_included
            @easy_agile_board_headers_tags_included = true
            content_for :header_tags do
              render partial: 'easy_agile_board/common_header', locals: { project: project, easy_sprint: easy_sprint }
            end
          end

        end
      end
    end
  end

end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyAgileBoard::ApplicationHelperPatch'
