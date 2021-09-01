ActiveSupport.on_load(:easyproject, yield: true) do
  # init permissions
  Redmine::AccessControl.map do |map|
    map.project_module :requirements do |pmap|
      pmap.permission(:view_requirements, {
        :requirements => [:index, :treeview, :tree, :load_settings,
          :find_project, :add_hidden_re_artifact_properties_attributes, :create_tree,
          :render_to_html_tree, :render_children_to_html_tree,
          :enhanced_filter, :find_first_artifacts_with_first_parameter,
          :reduce_search_result_with_parameter, :sendDiagramPreviewImage],
        :redmine_re => [:enhanced_filter, :index, :treeview, :tree, :load_settings,
          :find_project, :add_hidden_re_artifact_properties_attributes, :create_tree,
          :render_to_html_tree, :render_children_to_html_tree,
          :enhanced_filter, :find_first_artifacts_with_first_parameter,
          :reduce_search_result_with_parameter],
        :re_artifact_properties => [:show, :redirect, :history],
        :re_artifact_relationship => [:prepare_relationships, :visualization, :build_json_according_to_user_choice],
        :re_queries => [:index, :show, :query, :apply,
          :suggest_artifacts, :suggest_issues, :suggest_diagrams, :suggest_users,
          :artifacts_bits, :issues_bits, :diagrams_bits, :users_bits]
      })
      pmap.permission(:edit_requirements, {
        :requirements => [:index, :treeview, :tree, :context_menu, :load_settings,
          :find_project, :add_hidden_re_artifact_properties_attributes, :create_tree,
          :delegate_tree_drop, :render_to_html_tree, :render_children_to_html_tree,
          :enhanced_filter, :find_first_artifacts_with_first_parameter,
          :reduce_search_result_with_parameter, :sendDiagramPreviewImage, :add_relation],
        :redmine_re => [:enhanced_filter, :index, :treeview, :context_menu, :tree, :load_settings,
          :find_project, :add_hidden_re_artifact_properties_attributes, :create_tree,
          :delegate_tree_drop, :render_to_html_tree, :render_children_to_html_tree,
          :enhanced_filter, :find_first_artifacts_with_first_parameter,
          :reduce_search_result_with_parameter],
        :re_artifact_properties => [:show, :new, :create, :update, :edit, :redirect, :destroy, :autocomplete_parent, :autocomplete_issue,
          :autocomplete_artifact, :remove_issue_from_artifact, :remove_artifact_from_issue,
          :rate_artifact, :how_to_delete, :recursive_destroy, :history, :revert_to_version],
        :re_artifact_relationship => [:delete, :autocomplete_sink, :prepare_relationships,
          :visualization, :build_json_according_to_user_choice],
        :re_rationale => [:edit, :new],
        :re_queries => [:index, :new, :edit, :show, :delete, :create, :update, :query, :apply,
          :suggest_artifacts, :suggest_issues, :suggest_diagrams, :suggest_users,
          :artifacts_bits, :issues_bits, :diagrams_bits, :users_bits],
        re_artifact_baselines: [:new, :preview, :create, :update, :destroy, :revert]
      })
      pmap.permission(:administrate_requirements, {
        :requirements => [:setup, :import, :export, :bulk_change_status],
        :re_settings => [:configure, :new, :edit, :update, :create, :configure_fields, :edit_artifact_type_description]
      })

    end
  end

  # init menu
  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :re, {:controller => 'requirements', :action => 'index'}, :caption => 'Requirements', :after => :activity, :param => :project_id
  end

  # init artifact activity
  Redmine::Activity.map do |activity|
    activity.register :re_artifact_properties, {class_name: 'ReArtifactProperties', default: true}
  end

  require 'redmine_re/hooks'
end

# Make singular and plural for RE_Artifact_Properties the same
ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular /^(ReArtifactPropert)ies/i, '\1ies'
  inflect.plural /^(ReArtifactPropert)ies/i, '\1ies'
end

require_dependency File.dirname(__FILE__) + '/lib/re_wiki_macros'

#helper to controller
ActionView::Base.class_eval do
  include ReApplicationHelper
end

# TODO: in plain redmine without assets and in easy with assets
Rails.application.configure do
  config.assets.precompile += %w(suggestible.css jquery.qtip.css colorpicker.css icons.css jstree/default/style.css re_print.css redmine_re.css)
  config.assets.precompile += %w(query_form.js suggestible.js suggestible_custom.js jquery.autogrowtextarea.js re_artifacts_suggestible.js
  jquery.layout.state.js jquery.layout.js jquery.qtip.js jit.js ratings.js jquery.colorPicker.js jquery.tablednd.js re_task.js
  re_use_case.js jstree.js re_treebar.js re_filter.js redmine_re.js re_settings.js re_relation.js
  )
end

RedmineExtensions::Reloader.to_prepare do
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => ReArtifactPropertiesCustomField.name, :partial => 'custom_fields/index', :label => :label_redmine_re_artifact_custom_field_plural}
end