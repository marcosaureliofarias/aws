#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module AuthSourcesControllerTestPatch
#    extend RedmineTestPatch
#
#    repair_test :test_destroy_auth_source_in_use do
#      User.find(2).update_attribute :auth_source_id, 1
#
#      assert_no_difference 'AuthSourceLdap.count' do
#        delete :destroy, :id => 1
#        assert_redirected_to :action => 'move_users', :id => 1
#      end
#    end
#
#    repair_test :test_new do
#      get :new
#
#      assert_response :success
#      assert_template 'new'
#
#      source = assigns(:auth_source)
#      assert source.is_a?(AuthSourceLdap)
#      assert source.new_record?
#
#      assert_select 'form#auth_source_form' do
#        assert_select "input[name=type][value=#{source.class.name}]"
#        assert_select 'input[name=?]', 'auth_source[host]'
#      end
#    end
#
#  end
#end
