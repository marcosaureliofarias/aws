#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module ProjectsControllerTestPatch
#    extend RedmineTestPatch
#
#    setup do
#      Setting.login_required = '0'
#    end
#
#    disable_tests [
#        :test_create_should_preserve_modules_on_validation_failure,
#        :test_show_should_not_display_empty_sidebar,
#        :test_show_should_show_private_subprojects_that_are_visible,
#        :test_show_by_identifier,
#        :test_index_by_anonymous_should_not_show_private_projects,
#        :test_project_breadcrumbs_should_be_limited_to_3_ancestors,
#        #issue link is visible even if there are no trackers cuz it is in top menu - no point to test
#        :test_project_menu_should_include_new_issue_link,
#        :test_project_menu_should_not_include_new_issue_link_for_project_without_trackers,
#        # we do not see any CF on show page
#        :test_show_should_not_display_blank_custom_fields_with_multiple_values,
#        :test_project_breadcrumbs_should_be_limited_to_3_ancestors,
#        '#create by non-admin user with add_project permission should create a new project'
#      ]
#
#    prepare_test :test_post_copy_should_copy_requested_items do
#      CustomField.destroy_all
#    end
#
#    repair_test "#index by non-admin user with view_time_entries permission should show overall spent time link" do
#      @request.session[:user_id] = 3
#      get :index
#      assert_template 'index'
#
#      assert_select "a:match('href', ?)", /\/time_entries/ # /time_entries?set_filter=0
#    end
#
#    # we have permission view_all_statements to display time entries
#    # repair_test "#index by non-admin user without view_time_entries permission should not show overall spent time link" do
#    #   Role.find(2).remove_permission! :view_all_statements
#    #   Role.non_member.remove_permission! :view_all_statements
#    #   Role.anonymous.remove_permission! :view_all_statements
#    #   @request.session[:user_id] = 3
#    #
#    #   get :index
#    #   assert_template 'index'
#    #   assert_select "a[href^='/time_entries']", 0
#    # end
#
#    repair_test :test_archive do
#      @request.session[:user_id] = 1 # admin
#      post :archive, :id => 1
#      assert_redirected_to '/projects'
#      assert !Project.find(1).active?
#    end
#
#    repair_test :test_archive_with_failure do
#      @request.session[:user_id] = 1
#      Project.any_instance.stubs(:archive).returns(false)
#      post :archive, :id => 1
#      assert_redirected_to '/projects'
#      assert_match /project cannot be archived/i, flash[:error]
#    end
#
#    repair_test "#create by admin user should create a new project" do
#      @request.session[:user_id] = 1
#
#      post :create,
#        :project => {
#          :name => "blog",
#          :description => "weblog",
#          :homepage => 'http://weblog',
#          :identifier => "blog",
#          :is_public => 1,
#          :project_custom_field_ids => [ '3' ],
#          :custom_field_values => { '3' => 'Beta' },
#          :tracker_ids => ['1', '3'],
#          # an issue custom field that is not for all project
#          :issue_custom_field_ids => ['9'],
#          :enabled_module_names => ['issue_tracking', 'news', 'repository']
#        }
#      assert_redirected_to '/projects/blog/settings'
#
#      project = Project.find_by_name('blog')
#      assert_kind_of Project, project
#      assert project.active?
#      assert_equal 'weblog', project.description
#      assert_equal 'http://weblog', project.homepage
#      assert_equal true, project.is_public?
#      assert_nil project.parent
#      assert_equal 'Beta', project.custom_value_for(3).value
#      assert_equal [1, 3], project.trackers.map(&:id).sort
#      assert_equal ['issue_tracking', 'news', 'repository'], project.enabled_module_names.sort
#      assert project.issue_custom_fields.include?(IssueCustomField.find(9))
#    end
#
#    # needs to be on wiki tab
#    repair_test :test_setting_with_wiki_module_and_no_wiki do
#      Project.find(1).wiki.destroy
#      Role.find(1).add_permission! :manage_wiki
#      @request.session[:user_id] = 2
#
#      get :settings, :id => 1, :tab => 'wiki'
#      assert_response :success
#      assert_template 'settings'
#
#      assert_select 'form[action=?]', '/projects/ecookbook/wiki' do
#        assert_select 'input[name=?]', 'wiki[start_page]'
#      end
#    end
#
#    repair_test :test_post_copy_with_failure do
#      @request.session[:user_id] = 1
#      post :copy, :id => 1, :project => {:name => '', :identifier => ''}
#      assert_response :success
#      assert_template 'copy'
#    end
#
#  end
#end
