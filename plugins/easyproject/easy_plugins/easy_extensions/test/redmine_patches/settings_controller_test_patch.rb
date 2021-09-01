#require File.expand_path('../redmine_test_patch', __FILE__)
#
#module EasyExtensions
#  module SettingsControllerTestPatch
#    extend RedmineTestPatch
#
#    disable_test :test_get_edit_should_preselect_default_issue_list_columns
#    disable_test :test_post_plugin_settings
#    disable_test :test_edit_without_commit_update_keywords_should_show_blank_line # mame komplet predelane
#
#    repair_test :test_edit_commit_update_keywords do
#      with_settings :commit_update_keywords => [
#        {"keywords" => "fixes, resolves", "status_id" => "3"},
#        {"keywords" => "closes", "status_id" => "5", "done_ratio" => "100", "if_tracker_id" => "2"}
#      ] do
#        get :edit
#      end
#      assert_response :success
#      #   assert_select 'tr.commit-keywords', 2
#      #   assert_select 'tr.commit-keywords:nth-child(1)' do
#      #     assert_select 'input[name=?][value=?]', 'settings[commit_update_keywords][keywords][]', 'fixes, resolves'
#      #     assert_select 'select[name=?]', 'settings[commit_update_keywords][status_id][]' do
#      #       assert_select 'option[value=3][selected=selected]'
#      #     end
#      #   end
#      #   assert_select 'tr.commit-keywords:nth-child(2)' do
#      #     assert_select 'input[name=?][value=?]', 'settings[commit_update_keywords][keywords][]', 'closes'
#      #     assert_select 'select[name=?]', 'settings[commit_update_keywords][status_id][]' do
#      #       assert_select 'option[value=5][selected=selected]', :text => 'Closed'
#      #     end
#      #     assert_select 'select[name=?]', 'settings[commit_update_keywords][done_ratio][]' do
#      #       assert_select 'option[value=100][selected=selected]', :text => '100 %'
#      #     end
#      #     assert_select 'select[name=?]', 'settings[commit_update_keywords][if_tracker_id][]' do
#      #       assert_select 'option[value=2][selected=selected]', :text => 'Feature request'
#      #     end
#      #   end
#
#    end
#
#  end
#end
