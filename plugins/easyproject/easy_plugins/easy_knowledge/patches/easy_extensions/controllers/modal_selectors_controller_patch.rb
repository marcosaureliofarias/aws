module EasyKnowledge
  module ModalSelectorsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_knowledge_global_categories
          retrieve_query(EasyKnowledgeCategoryQuery)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_knowledge_category.default') : l("easy_query.easy_lookup.name.easy_knowledge_category.#{params[:query_name]}"))

          set_query(@query)

          sort_init(@query.sort_criteria.empty? ? [['lft', 'asc']] : @query.sort_criteria)
          sort_update({'id' => "#{EasyKnowledgeCategory.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
          @query.entity_scope = EasyKnowledgeCategory.global
          # query.additional_statement = "#{EasyKnowledgeCategory.table_name}.entity_type IS NULL AND #{EasyKnowledgeCategory.table_name}.entity_id IS NULL"

          prepare_easy_query_render(@query)

          if request.xhr? && !@entities
            render_404
            return false
          end

          if loading_group?
            render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
          end
        end

        def easy_knowledge_personal_categories
          retrieve_query(EasyKnowledgeCategoryQuery)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_knowledge_category.default') : l("easy_query.easy_lookup.name.easy_knowledge_category.#{params[:query_name]}"))

          set_query(@query)

          sort_init(@query.sort_criteria.empty? ? [['lft', 'asc']] : @query.sort_criteria)
          sort_update({'id' => "#{EasyKnowledgeCategory.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
          @query.entity_scope = EasyKnowledgeCategory.category_by_user(User.current)
          # query.additional_statement = "#{EasyKnowledgeCategory.table_name}.entity_type = 'Principal' AND #{EasyKnowledgeCategory.table_name}.entity_id = #{User.current.id}"

          prepare_easy_query_render(@query)

          if request.xhr? && !@entities
            render_404
            return false
          end

          if loading_group?
            render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
          end
        end

        def easy_knowledge_project_categories
          retrieve_query(EasyKnowledgeCategoryQuery)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_knowledge_category.default') : l("easy_query.easy_lookup.name.easy_knowledge_category.#{params[:query_name]}"))

          set_query(@query)

          sort_init(@query.sort_criteria.empty? ? [['lft', 'asc']] : @query.sort_criteria)
          sort_update({'id' => "#{EasyKnowledgeCategory.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))

          @query.entity_scope = EasyKnowledgeCategory.category_by_project(@modal_project)

          prepare_easy_query_render(@query)

          if request.xhr? && !@entities
            render_404
            return false
          end

          if loading_group?
            render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
          end
        end

        def easy_knowledge_story
          retrieve_query(EasyKnowledgeStoryQuery)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_knowledge_story.default') : l("easy_query.easy_lookup.name.easy_knowledge_story.#{params[:query_name]}"))

          set_query(@query)

          sort_init(@query.sort_criteria.empty? ? [['name', 'asc']] : @query.sort_criteria)
          sort_update({'id' => "#{EasyKnowledgeStory.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))

          prepare_easy_query_render(@query)

          if request.xhr? && !@entities
            render_404
            return false
          end

          if loading_group?
            render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
          end
        end

        def easy_knowledge_issue
          retrieve_query(EasyKnowledgeIssueQuery)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_knowledge_issue.default') : l("easy_query.easy_lookup.name.easy_knowledge_issue.#{params[:query_name]}"))

          set_query(@query)

          sort_init(@query.sort_criteria.empty? ? [['name', 'asc']] : @query.sort_criteria)
          sort_update({'lft' => "#{Project.table_name}.lft"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))

          prepare_easy_query_render(@query)

          if request.xhr? && !@entities
            render_404
            return false
          end

          if loading_group?
            render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
          end
        end

        def easy_knowledge_project
          retrieve_query(EasyProjectQuery)
          @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.project.default') : l("easy_query.easy_lookup.name.project.#{params[:query_name]}"))

          set_query(@query)

          sort_init(@query.sort_criteria_init)
          sort_update({'lft' => "#{Project.table_name}.lft"}.merge(@query.sortable_columns))
          @query.entity_scope = @query.entity_scope.has_module(:easy_knowledge)
          @query.add_additional_statement "(#{Project.table_name}.easy_is_easy_template=#{@query.class.connection.quoted_false} AND #{Project.visible_condition(User.current)})"

          prepare_easy_query_render(@query)

          if request.xhr? && !@entities
            render_404
            return false
          end

          options = {:button_close_label => l('modal_labels.cancel'), :button_close_title => l('modal_titles.cancel')}

          if loading_group?
            render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
          else
            render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count, options)
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ModalSelectorsController', 'EasyKnowledge::ModalSelectorsControllerPatch'
