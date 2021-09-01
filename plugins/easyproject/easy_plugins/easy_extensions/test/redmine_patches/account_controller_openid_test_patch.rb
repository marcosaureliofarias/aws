#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module AccountControllerOpenidTestPatch
#    extend RedmineTestPatch
#
#    repair_test :test_login_with_openid_with_new_user_created do
#      Setting.self_registration = '3'
#      post :login, :openid_url => 'http://openid.example.com/good_user'
#      user = User.find_by_login('cool_user')
#      assert_redirected_to "/users/#{user.id}/profile"
#      assert user
#      assert_equal 'Cool', user.firstname
#      assert_equal 'User', user.lastname
#    end
#
#  end
#end
