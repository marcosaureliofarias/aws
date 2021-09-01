#
# This helper is prepended into ApplicationHelper and
# should contains only things related to easy pages.
#
# It's done this way because of problem with including
# module to module which is already included.
#
module EasyConcerns
  module EasyPagesHelper
    extend ActiveSupport::Concern

    included do

      def render_easy_page_bottom_buttons(url = nil)
        url ||= { action: 'layout', t: params[:t] }

        content_for(:easy_page_layout_service_box_bottom) do
          content_tag(:div, class: 'customize-button-container') do
            link_to(l(:label_personalize_page), url, class: 'customize-button button')
          end
        end
      end

      # Also see `EasyExtensions::GlobalFilters`
      # TODO: Move logic into more appropriate class
      #       CF into FieldFormat
      #       Rest into EasyExtensions::GlobalFilters
      def available_global_filters_for_query(query)
        result = Hash.new { |hash, type| hash[type] = [] }

        query.available_filters.each do |attribute, options|
          filter_data_type = options[:data_type]
          case filter_data_type
          when :user, :project, :sprint, :version
            result[filter_data_type] << { name: options[:name], filter: attribute }
            next
          end

          if options[:field]
            case options[:field].field_format
            when 'country_select'
              result[:country_select] << { name: options[:name], filter: attribute }
              next
            when 'easy_lookup'
              case options[:field].settings['entity_type']
              when 'Project'
                result[:project] << { name: options[:name], filter: attribute }
                next
              when 'User'
                result[:user] << { name: options[:name], filter: attribute }
                next
              end
            when 'user'
              result[:user] << { name: options[:name], filter: attribute }
              next
            end
          end

          case attribute.to_sym
          when :author_by_group, :member_of_group, :user_group, :group_id, :issue_author_by_group, :user_groups
            result[:user_group] << { name: options[:name], filter: attribute }
            next
          end

          filter_type = options[:type]
          case filter_type
          when :date_period
            result[filter_type] << { name: options[:name], filter: attribute }
            result[:date_from_to_period] << { name: options[:name], filter: attribute }
            next
          when :country_select, :list_optional
            result[filter_type] << { name: options[:name], filter: attribute }
            next
          end
        end

        result.to_h
      end

      def global_filters_as_hidden_fields
        result = ''
        params.each do |key, value|
          if key.start_with?('global_filter_') && key =~ /\Aglobal_filter_(\d+)\Z/
            result << hidden_field_tag(key, value)
          end
        end
        result.html_safe
      end

    end

  end
end
