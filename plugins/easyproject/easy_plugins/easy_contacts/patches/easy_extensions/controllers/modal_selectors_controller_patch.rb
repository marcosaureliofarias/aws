module EasyContacts
  module ModalSelectorsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

      end
    end

    module InstanceMethods

      def easy_contact_for_mail
        retrieve_query(EasyUserQuery)
        @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.user.default') : l("easy_query.easy_lookup.name.user.#{params[:query_name]}"))

        set_query(@query)

        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        prepare_easy_query_render

        if request.xhr? && !@entities
          render_404
          return false
        end

        options = {:button_selector_assign_label => l('modal_labels.mail'), :button_selector_assign_title => l('modal_titles.mail'),:button_close_label => l('modal_labels.cancel'), :button_close_title => l('modal_titles.cancel')}

        if loading_group?
          render_easy_query_html(@query, nil, {:selected_values => prepare_selected_values})
        else
          render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count, options)
        end
      end

      def easy_contact_for_project
        retrieve_query(EasyProjectQuery)
        @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.project.default') : l("easy_query.easy_lookup.name.project.#{params[:query_name]}"))

        set_query(@query)

        sort_init(@query.sort_criteria_init)
        sort_update({'lft' => "#{Project.table_name}.lft"}.merge(@query.sortable_columns))

        @query.entity_scope = @query.entity_scope.has_module(:easy_contacts)
        @query.add_additional_statement("(#{Project.table_name}.easy_is_easy_template=#{@query.class.connection.quoted_false} AND #{Project.visible_condition(User.current)})")

        prepare_easy_query_render

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

      def easy_contact_group
        retrieve_query(EasyContactGroupQuery)
        @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_contact_group.default') : l("easy_query.easy_lookup.name.easy_contact_group.#{params[:query_name]}"))
        table_name = EasyContactGroup.table_name

        set_query(@query)

        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        @query.group_by = 'group_type'

        additional_statement = " #{table_name}.entity_id IS NULL OR (#{table_name}.entity_id = #{User.current.id} AND (#{table_name}.entity_type <> 'Projects' AND #{table_name}.entity_type IS NOT NULL))"
        if @modal_project
          additional_statement << " OR (#{table_name}.entity_id = #{@modal_project.id} AND #{table_name}.entity_type = 'Project')"
        else
          additional_statement << " OR #{table_name}.entity_type = 'Project'" if User.current.admin?
        end
        @query.add_additional_statement(additional_statement)

        prepare_easy_query_render

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

      def easy_contact
        retrieve_query(EasyContactQuery)
        @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_contact.default') : l("easy_query.easy_lookup.name.easy_contact.#{params[:query_name]}"))
        @query.add_additional_scope(EasyContact.where.not(id: params[:ids]))
        set_query(@query, nil, skip_project_filter: true)

        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        prepare_easy_query_render

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

      def easy_contact_for_partner
        retrieve_query(EasyContactQuery)
        @query.name = (params[:query_name].blank? ? l('easy_query.easy_lookup.name.easy_contact_partner.default') : l("easy_query.easy_lookup.name.easy_contact.#{params[:query_name]}"))
        set_query(@query, nil, skip_project_filter: true)
        @query.add_short_filter('type_id', '=' + EasyContact.partner_type_id)

        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        prepare_easy_query_render

        if request.xhr? && !@entities
          render_404
          return false
        end

        if loading_group?
          render_easy_query_html(@query, nil, { selected_values: prepare_selected_values })
        else
          render_modal_selector_entities_list(@query, @entities, @entity_pages, @entity_count)
        end
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch('ModalSelectorsController', 'EasyContacts::ModalSelectorsControllerPatch')
