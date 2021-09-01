#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module UsersControllerTestPatch
#    extend RedmineTestPatch
#
#    repair_test :test_index do
#      get :index
#      assert_response :success
#      assert_template 'index'
#      assert_not_nil assigns(:users)
#    end
#
#    repair_test :test_index_with_group_filter do
#      get :index, :group_id => '10'
#      assert_response :success
#      assert_template 'index'
#      users = assigns(:users)
#      assert users.any?
#      assert_equal([], (users - Group.find(10).users))
#      assert assigns(:query).has_filter?('groups')
#    end
#
#    repair_test :test_index_with_name_filter do
#      get :index, :set_filter => 1, :name => 'john'
#      assert_response :success
#      assert_template 'index'
#      users = assigns(:users)
#      assert_not_nil users
#      assert_equal 1, users.size
#      assert_equal 'John', users.first.firstname
#    end
#
#    repair_test :test_show do
#      @request.session[:user_id] = 2
#      get :show, :id => 2
#      assert_response :success
#      assert_template 'show'
#      assert_not_nil assigns(:user)
#
#      assert_select 'th', :text => /Phone number/
#    end
#
#    repair_test :test_show_should_not_display_hidden_custom_fields do
#      @request.session[:user_id] = 2
#      UserCustomField.find_by_name('Phone number').update_attribute :visible, false
#      get :show, :id => 2
#      assert_response :success
#      assert_template 'show'
#      assert_not_nil assigns(:user)
#
#      assert_select 'th', :text => /Phone number/, :count => 0
#    end
#
#  end
#end
