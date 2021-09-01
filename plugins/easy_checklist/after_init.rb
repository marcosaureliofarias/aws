ActiveSupport.on_load(:easyproject, yield: true) do
  require 'hooks'
  require 'easy_checklist/proposer'

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :easy_checklist_templates, :easy_checklists_path, if: proc { User.current.allowed_to_globally?(:manage_easy_checklist_templates) }, html: {class: 'icon icon-workflow'}, before: :settings
  end

  Redmine::AccessControl.map do |map|
    map.project_module :easy_checklists do |pmap|
      pmap.permission :view_easy_checklists, {}
      pmap.permission :create_easy_checklists, {easy_checklists: [:create]}
      pmap.permission :change_easy_checklists_layout, {easy_checklists: [:update_display_mode]}
      pmap.permission :delete_easy_checklists, {easy_checklists: [:destroy]}
      pmap.permission :manage_easy_checklist_templates, {easy_checklists: [:index, :new, :create, :edit, :update, :settings, :destroy]}
      pmap.permission :create_easy_checklist_from_template, {easy_checklists: [:add_to_entity, :append_template]}
      pmap.permission :enable_easy_checklist_items, {easy_checklist_items: [:update]}
      pmap.permission :disable_easy_checklist_items, {easy_checklist_items: [:update]}
      pmap.permission :create_easy_checklist_items, {easy_checklist_items: [:new, :create]}
      pmap.permission :edit_easy_checklist_items, {easy_checklist_items: [:edit, :update]}
      pmap.permission :delete_easy_checklist_items, {easy_checklist_items: [:destroy]}
    end
  end

  RedmineExtensions::EasySettingPresenter.boolean_keys.concat [:easy_checklist_use_project_settings, :easy_checklist_enable_history_changes, :easy_checklist_enable_change_done_ratio]
end
