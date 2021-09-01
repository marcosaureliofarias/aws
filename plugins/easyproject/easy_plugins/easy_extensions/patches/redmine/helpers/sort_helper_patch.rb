module EasyPatch
  module SortHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :sort_update, :easy_extensions
        alias_method_chain :sort_css_classes, :easy_extensions
        alias_method_chain :sort_link, :easy_extensions

      end
    end

    module InstanceMethods

      def sort_update_with_easy_extensions(criteria, sort_name = nil)
        sort_update_without_easy_extensions(criteria, sort_name)
        if @query
          @query.sort_criteria = Array(@sort_criteria)
        end
      end

      def sort_css_classes_with_easy_extensions
        @sort_criteria ? sort_css_classes_without_easy_extensions : ''
      end

      def sort_link_with_easy_extensions(column, caption, default_order)
        css, order = nil, default_order

        if column.to_s == @sort_criteria.first_key
          if @sort_criteria.first_asc?
            css = 'sort asc'
            order = 'desc'
          else
            css = 'sort desc'
            order = 'asc'
          end
        end
        caption = column.to_s.humanize unless caption

        sort_options = { sort: @sort_criteria.add(column.to_s, order).to_param }
        link_to(caption, {params: request.query_parameters.merge(sort_options)}, class: css)
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'SortHelper', 'EasyPatch::SortHelperPatch'
