#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module AccountControllerTestPatch
#    extend RedmineTestPatch
#
#    repair_test :test_post_register_with_registration_on do
#      with_settings :self_registration => '3' do
#        assert_difference 'User.count' do
#          post :register, :user => {
#            :login => 'register',
#            :password => 'secret123',
#            :password_confirmation => 'secret123',
#            :firstname => 'John',
#            :lastname => 'Doe',
#            :mail => 'register@example.com'
#          }
#        end
#        user = User.order('id DESC').first
#        assert_redirected_to "/users/#{user.id}/profile"
#        assert_equal 'register', user.login
#        assert_equal 'John', user.firstname
#        assert_equal 'Doe', user.lastname
#        assert_equal 'register@example.com', user.mail
#        assert user.check_password?('secret123')
#        assert user.active?
#      end
#    end
#
#  end
#end
