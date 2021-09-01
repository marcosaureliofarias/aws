#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module RolesControllerTestPatch
#    extend RedmineTestPatch
#
#    repair_test :test_destroy_role_in_use do
#      assert_no_difference 'Role.count' do
#        delete :destroy, :id => 1
#      end
#      assert_redirected_to :action => 'move_members', :id => 1
#      assert_not_nil flash[:error]
#    end
#
#  end
#end
