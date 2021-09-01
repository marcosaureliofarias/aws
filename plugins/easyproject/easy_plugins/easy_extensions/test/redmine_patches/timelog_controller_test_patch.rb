#require File.expand_path('../redmine_test_patch', __FILE__)
#
#
#module EasyExtensions
#  module TimelogControllerTestPatch
#    extend RedmineTestPatch
#
#    disable_tests_of_action(:new)
#
#    disable_test :test_get_edit_with_an_existing_time_entry_with_inactive_activity
#    disable_test :test_index_with_filter_on_issue_custom_field #easyproject does not support it yet
#    disable_test :test_create_without_project_with_failure #easyproject does not support project selecting if selected already
#    disable_test :test_index_with_display_subprojects_issues_to_false_and_subproject_filter_should_include_subproject_entries #easyproject does not support project selecting if selected already
#
#    #queries should be tested in easy tests
#    disable_tests [
#      :test_index_with_time_entry_custom_field_sorting,
#      :test_index_with_time_entry_custom_field_column,
#      :test_index_with_issue_custom_field_column,
#      :test_index_at_project_level_with_date_range,
#      :test_index_should_sort_by_spent_on_and_created_on
#    ]
#    # easyproject does not have csv export dialog
#    disable_tests [
#      :test_index_at_issue_level_should_include_csv_export_dialog,
#      :test_index_at_project_level_should_include_csv_export_dialog,
#      :test_index_cross_project_should_include_csv_export_dialog,
#      :test_index_csv_should_fill_issue_column_with_tracker_id_and_subject
#    ]
#
#    def self.included(base)
#      base.class_eval do
#
#        def get_with_easy_timelog_patch(action, *args)
#          if action == :index
#            params = args.detect{|arg| arg.is_a?(Hash)}
#            unless params
#              params = {}
#              args << params
#            end
#            @request.session[:user_id] ||= 1
#
#            params[:set_filter] = '1'
#            params[:spent_on] = 'all'
#          end
#          get_without_easy_timelog_patch(action, *args)
#        end
#
#        def assert_tag_with_easy_timelog_patch(*opts)
#          tag = (opts.size > 1 ? opts.first : opts.first[:tag]).to_s
#          params = opts.last
#          params = {} unless params.is_a?(Hash)
#
#          if tag == 'a' && params[:attributes] && params[:attributes][:href] == '/time_entries/new'
#            params[:attributes][:href] = "/bulk_time_entries"
#          end
#          if tag == 'form' && params[:attributes] && params[:attributes][:id] == 'query_form'
#            params[:attributes].delete(:action)
#          end
#
#          assert_tag_without_easy_timelog_patch(*opts)
#        end
#
#        def assert_include_with_easy_timelog_patch(*opts)
#          if opts.any? && opts.first == "Issue is invalid"
#            opts.first.gsub!(/Issue/, 'Task')
#          end
#          assert_include_without_easy_timelog_patch(*opts)
#        end
#
#        def assert_equal_with_easy_timelog_patch(exp, act, msg = nil)
#          if exp == 'text/csv; header=present'
#            assert_equal_without_easy_timelog_patch(Mime::CSV, act, msg)
#          else
#            assert_equal_without_easy_timelog_patch(exp, act, msg)
#          end
#
#        end
#
#        def assert_select_with_easy_timelog_patch(*args)
#          selector = args.shift
#          if selector =~ /form#query_form/
#            selector.sub!(/form#query_form/, 'form#easy-query-list-time-entry')
#          end
#          args.unshift(selector)
#          assert_select_without_easy_timelog_patch(*args)
#        end
#
#
#        alias_method_chain :get, :easy_timelog_patch
#        alias_method_chain :assert_tag, :easy_timelog_patch
#        alias_method_chain :assert_include, :easy_timelog_patch
#        alias_method_chain :assert_equal, :easy_timelog_patch
#        alias_method_chain :assert_select, :easy_timelog_patch
#
#      end
#
#      super
#    end
#
#    repair_test :test_index_all_projects_should_show_log_time_link do
#      @request.session[:user_id] = 2
#      get :index
#      assert_response :success
#      assert_template 'index'
#      assert_select 'a[href=?]', '/bulk_time_entries', :text => /Log time/
#    end
#
#  end
#end
