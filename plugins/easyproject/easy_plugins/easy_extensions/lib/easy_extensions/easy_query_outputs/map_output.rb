module EasyExtensions
  module EasyQueryOutputs
    class MapOutput < EasyExtensions::EasyQueryHelpers::EasyQueryOutput

      def self.available_for?(query)
        query.entity.respond_to?(:geocoder_options) && query.entity.geocoder_options[:latitude] && query.entity.geocoder_options[:longitude] ||
            (query.entity.column_names & ['latitude', 'longitude']).any?
      end

      def latitude_column_name
        query.entity.respond_to?(:geocoder_options) ? query.entity.geocoder_options[:latitude] : 'latitude'
      end

      def longitude_column_name
        query.entity.respond_to?(:geocoder_options) ? query.entity.geocoder_options[:longitude] : 'longitude'
      end

      def before_render
        @scope_was            = query.entity_scope
        at                    = query.entity.arel_table
        query.entity_scope    = @scope_was.where(at[latitude_column_name].not_eq(nil)).where(at[longitude_column_name].not_eq(nil))
        query.disable_columns = true
      end

      def after_render
        query.entity_scope    = @scope_was
        query.disable_columns = false
      end

      def map_tiles_url
        'http://{s}.tile.osm.org/{z}/{x}/{y}.png'
      end

      def map_tile_layer_options
        { attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors' }
      end

      def api_data
        query.entities(fetch: true).collect do |entity|
          {
              id:          entity.id,
              link:        h.link_to_entity(entity),
              title:       entity.to_s,
              coordinates: [entity.send(latitude_column_name), entity.send(longitude_column_name)]
          }
        end
      end

    end
  end
end
