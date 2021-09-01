module ModalSelectorTagsHelper
  def self.included(base)

    base.class_eval do

      # Renders modal selector field tag
      #
      # entity_type = 'Issue' or 'Project' or 'User'
      # entity_attribute = 'name' or 'subject' or 'link_with_name'
      # field_name = 'issue[custom_field_values][40]'
      # field_id = 'issue_custom_field_values_40_'
      # selected_values = { 2 => 'Firstname Lastname', 5 => 'Firstname2 Lastname2'}
      #                   or call EasyExtensions::FieldFormats::EasyLookup.entity_to_lookup_values(users)
      #                   or call EasyExtensions::FieldFormats::EasyLookup.entity_to_lookup_values(issues, :display_name => :subject)
      #                   or call EasyExtensions::FieldFormats::EasyLookup.entity_to_lookup_values(issues, :display_name => Proc.new{|issue| link_to_issue(issue)})
      # options:
      #   :url => { :additional_param1 => 'value1', :additional_param2 => 'value2'}
      #   :multiple => '1' or '0'
      def easy_modal_selector_field_tag(entity_type, entity_attribute, field_name, field_id, selected_values = {}, options = {})
        entity_type_underscored = entity_type.underscore
        options[:url]           ||= {}
        if options.key?(:multiple)
          options[:url][:multiple] = options.delete(:multiple)
        else
          options[:url][:multiple] = '1'
        end
        if options[:url][:multiple] == '1'
          field_name += '[]' unless /\[\]$/.match?(field_name)
        end

        main_css = "easy-lookup #{field_id}"
        field_id.gsub! /[\[\]]/, '_'
        main_css << ' multiple' if options[:url][:multiple] == '1'
        main_css << ' required' if options[:required]

        url = url_for({
                          :controller          => 'modal_selectors',
                          :entity_action       => entity_type_underscored,
                          :entity_attribute    => entity_attribute,
                          :entity_custom_field => options[:custom_field_id],
                          :field_name          => field_name,
                          :field_id            => field_id
                      }.merge(options[:url]))

        render(:partial => 'modal_selectors/tag_easy_modal_selector_field_tag', :locals => {
            :entity_type             => entity_type,
            :field_name              => field_name,
            :field_id                => field_id,
            :url                     => url,
            :main_css                => main_css,
            :entity_type_underscored => entity_type_underscored,
            :selected_values         => selected_values,
            :options                 => options
        })
      end

      # Render link _switching_ _to_ _fullscreen_
      # * element_id - muste exist, its container with content to fullscreen
      # * options - you can change lable & title of buttons and add paramteres to future
      def easy_modal_selector_link_to_fullscreen(element_id, options = {})
        options[:button_fullscreen_label] ||= l(:button_fullscreen)
        options[:button_fullscreen_title] ||= l(:title_fullscreen)
        options[:button_close_label]      ||= l(:button_back)
        options[:button_close_title]      ||= l(:button_back)

        link_to_function(options[:button_fullscreen_label], "EASY.modalSelector.showFullscreen('#{element_id}','#{options[:button_close_label]}','#{options[:button_close_title]}')",
                         :title => options[:button_fullscreen_title],
                         :class => options[:class])
      end

      def easy_modal_selector_link_to_fullscreen_by_ajax(url, options = {})

        options[:button_fullscreen_label] ||= l(:button_fullscreen)
        options[:button_fullscreen_title] ||= l(:title_fullscreen)
        options[:complete]                ||= 'null'

        link_to_function(options[:button_fullscreen_label], "showModal('ajax-modal', '99%')",
                         :title => options[:button_fullscreen_title],
                         :class => options[:class])

      end

      # Renders modal selector link with submit
      #
      # entity_type = 'Issue' or 'Project' or 'User'
      # entity_attribute = 'name' or 'subject' or 'link_with_name'
      # field_name = string - unique field name. This name will be send to :form_url
      # field_id = string - unique field id. This id will be used to data manipulation. Should be same as field_name. (char '[' and ']' will be '_')
      # js_serialize_elements_collection = something like '$(\'issues-form\').getInputs(\'checkbox\', \'ids[]\')'. It is array of all selected elements (checkboxes) from any source list.
      # options:
      #   :form_url => {:controller => '', :action => ''}
      #   :form_options => {:class => 'tabular'}
      #   :url => { :additional_param1 => 'value1', :additional_param2 => 'value2'}}
      #   :trigger_options => {:name => l(:button_send_email), :html => {:title => l(:title_send_email)}}
      def easy_modal_selector_link_with_submit(entity_type, entity_attribute, field_name = '', field_id = '', js_serialize_elements_collection = '[]', options = {})
        options[:trigger_options] ||= {}

        options[:url] ||= {}
        if options.key?(:multiple)
          options[:url][:multiple] = options.delete(:multiple)
        else
          options[:url][:multiple] = '1'
        end
        if options[:url][:multiple] == '1'
          field_name += '[]' unless /\[\]$/.match?(field_name)
        end

        entity_type_underscored = entity_type.underscore

        form_url               = options[:form_url] || {}
        form_options           = { :id => (field_id + '-form'), :style => 'display:none' }.merge((options[:form_options] || {}))
        trigger_options        = options[:trigger_options] || {}
        trigger_options[:html] ||= {}
        trigger_options[:html].reverse_merge!({ :id => "#{field_id}_lookup_trigger" })

        url = url_for({
                          :controller       => 'modal_selectors',
                          :entity_action    => entity_type_underscored,
                          :entity_attribute => entity_attribute,
                          :field_name       => field_name,
                          :field_id         => field_id }.merge(options[:url])
        )
        render(:partial => 'modal_selectors/tag_easy_modal_selector_link_with_submit', :locals => {
            :entity_type                      => entity_type,
            :field_name                       => field_name,
            :field_id                         => field_id,
            :url                              => url,
            :entity_type_underscored          => entity_type_underscored,
            :form_url                         => form_url,
            :form_options                     => form_options,
            :trigger_options                  => trigger_options,
            :js_serialize_elements_collection => js_serialize_elements_collection,
            :selected_values                  => options[:selected_values] || {},
            :options                          => options
        })
      end

      def render_modal_selector_easy_query_entities_list(query, entities, entity_pages, entity_count, selected_values, options)
        render query, :partial => 'easy_queries/easy_query_entities_list', :entities => entities, :entity_pages => entity_pages, :entity_count => entity_count, :selected_values => selected_values, :options => { :render_index => false, :modal_selector => true, :hascontextmenu => false }.merge(options)
      end

      def render_modal_selector_easy_query_list(query, entities, entity_pages, entity_count, selected_values, options, &entity_link_block)
        render(:partial => 'modal_selectors/modal_selector_easy_query_list', :locals => { :query => query, :entities => entities, :entity_pages => entity_pages, :entity_count => entity_count, :selected_values => selected_values, :options => options, :entity_link_block => entity_link_block })
      end

    end
  end
end
