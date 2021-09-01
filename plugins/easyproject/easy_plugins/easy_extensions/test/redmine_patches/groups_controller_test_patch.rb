#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module GroupsControllerTestPatch
#    extend RedmineTestPatch
#
#    repair_test :test_edit do
#      get :edit, :id => 10
#      assert_response :success
#      assert_template 'edit'
#
#      assert_select 'div#tab-content-general'
#      assert_select 'a[href="/groups/10/edit?tab=users"]'
#      assert_select 'a[href="/groups/10/edit?tab=memberships"]'
#    end
#
#  end
#end
