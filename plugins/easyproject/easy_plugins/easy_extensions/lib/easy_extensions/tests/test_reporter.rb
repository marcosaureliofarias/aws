require 'rubygems'
require 'active_resource'

module EasyExtensions
  module Tests

    class Resource < ActiveResource::Base

      class << self
        attr_reader :api_key

        def api_key=(key)
          @api_key                          = key
          self.headers["X-Redmine-API-Key"] = key
        end
      end

    end

    # Issue model on the client side
    class Issue < Resource
      class << self
        def instantiate_collection_with_issue(collection, prefix_options = {})
          instantiate_collection_without_issue(collection['issues'], prefix_options)
        end

        alias_method_chain :instantiate_collection, :issue
      end
    end

    class Project < Resource
    end

    class TestReporter

      class << self
        attr_reader :default_api_key
      end

      def initialize(server, project_id, api_key = nil)
        EasyExtensions::Tests::Issue.site      = server
        EasyExtensions::Tests::Project.site    = server
        EasyExtensions::Tests::Issue.api_key   = api_key || self.class.default_api_key
        EasyExtensions::Tests::Project.api_key = api_key || self.class.default_api_key
        @project                               = EasyExtensions::Tests::Project.find(project_id) if project_id

      rescue ActiveResource::ResourceNotFound => e
        $stderr.puts "ActiveResource was not able to find a Project with id #{project} on server #{server} with key #{api_key}"
        raise e
      end

      def report(parser, issue_id = nil)
        results = parser.get_results

        if Rails.root.to_s =~ /\/([^\/]+)\/public_html/
          folder = $1
        else
          folder = Rails.root
        end

        success_all = true

        results.each do |result|
          next if result.all_ok?
          success_all = false

          result.failured.each do |failure|
            failure.normalize_paths!

            subject = failure.subject

            if issue_id.nil?
              issue = EasyExtensions::Tests::Issue.find(:first, :params => { project_id: @project.id, columns: 'all', set_filter: '1', subject: "~#{subject}" })
            else
              issue           = EasyExtensions::Tests::Issue.find(issue_id)
              issue.easy_type = 'easy_ci'
            end

            unless issue
              issue             = EasyExtensions::Tests::Issue.create(subject: subject, project_id: @project.id, tracker_id: 7, status_id: 1, priority_id: 4)
              issue.description = "<h2>#{failure.heading}</h2>\n<p>File: <strong>#{failure.file}</strong>:#{failure.file_line}</p>\n" if failure.file
            end

            info = Array.new
            info << "<h4>#{failure.heading}</h4>"
            info << "<strong>Informations: </strong>"
            info << '<ul>'
            info << " <li>File: <strong>#{failure.file}:#{failure.file_line}</strong></li>" if failure.file
            info << " <li>Git-repo: <strong>#{%x(git config --get remote.origin.url)}</strong></li>"
            info << " <li>Git-branch: <strong>#{%x(git rev-parse --abbrev-ref HEAD)}</strong></li>"
            info << " <li>Full Version: <strong>#{EasyExtensions.full_version}</strong></li>"
            info << " <li>Platform Version: <strong>#{EasyExtensions.platform_version}</strong></li>"
            info << " <li>Database driver: <strong>#{Rails.configuration.database_configuration[Rails.env]['adapter']}</strong></li>"
            info << " <li>Rake: <strong>#{result.rake}</strong></li>"
            info << " <li>Folder: <strong>#{Rails.root.relative_path_from(Pathname.new('/data/www')) rescue Rails.root}</strong></li>"
            info << '</ul>'

            info << '<div>'
            info << "<strong>Message</strong>"
            info << '<p>' + failure.main_info.to_s + '</p>'
            info << '</div>'

            info << '<div class="module-toggle-button manual"><div class="group"><span class="expander">&nbsp;</span><h4 class="module-heading">Details</h4></div></div>'
            info << '<div style="display:none;">'
            info << "<p><pre>#{ERB::Util.h(failure.info)}</pre></p>"
            info << '</div>'

            issue.notes     = info.join("\n")
            issue.status_id = 1 if issue_id.nil?
            issue.save
          end

        end

        return success_all

      rescue ActiveResource::ResourceNotFound => e
        $stderr.puts "ActiveResource was not able to create a Issue #{subject} on server #{server} with key #{api_key}"
        raise e
      end

    end # TestReporter

  end
end
