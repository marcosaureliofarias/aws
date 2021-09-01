module EasyExtensions
  module EasyQueryOutputs
    class ListOutput < EasyExtensions::EasyQueryHelpers::EasyQueryOutput

      def self.displays_snapshot?
        true
      end

      def data_partial
        variables[:partial] || 'easy_queries/easy_query_entities_list'
      end

      def order
        1000
      end

      def render_data
        if @query.is_snapshot? && !@query.snapshotable_columns?
          h.content_tag(:p, h.l(:label_easy_query_snapshot_no_snapshotable_columns), class: 'nodata')
        elsif query.entities.blank?
          h.content_tag(:p, h.l(:label_no_data), class: 'nodata')
        else
          h.content_tag(:div, id: options[:container_id]) do
            h.render partial: data_partial, locals: variables
          end
        end
      end

    end
  end
end
