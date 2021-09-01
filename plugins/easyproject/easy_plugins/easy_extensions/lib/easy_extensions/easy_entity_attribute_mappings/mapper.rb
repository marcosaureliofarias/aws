module EasyExtensions
  module EasyEntityAttributeMappings
    class Mapper

      def self.map_entity(maps, entity_from, entity_to)
        if maps.any?
          custom_field_values = {}
          maps.each do |map|
            x_from = map.entity_from_attribute.match(/cf_(\d+)/)
            x_to   = map.entity_to_attribute.match(/cf_(\d+)/)
            # Get value _from_
            if x_from
              value = entity_from.custom_field_values.detect { |v| v.custom_field_id == x_from[1].to_i }.try(x_to ? :value : :cast_value)
            else
              if entity_from.respond_to?(map.entity_from_attribute)
                value = entity_from.send(map.entity_from_attribute)
              else
                next
              end
            end
            # Set value _to_
            if x_to
              custom_field_values.store(x_to[1], value)
            else
              entity_to.send("#{map.entity_to_attribute}=", value) if entity_to.respond_to?("#{map.entity_to_attribute}=")
            end
          end
          if custom_field_values.present?
            entity_to.custom_field_values = custom_field_values
          end
        else
          return nil
        end

        entity_to
      end

      def initialize(from_instance, to_class, options = nil)
        @options     = options || {}
        @entity_from = from_instance
        @entity_to   = (to_class.is_a?(String) && to_class.constantize || to_class).new

        @easy_entity_attribute_maps = EasyEntityAttributeMap.where(:entity_from_type => @entity_from.class.name, :entity_to_type => @entity_to.class.name)
      end

      def map_entity(entity_to = nil)
        entity_to ||= @entity_to
        raise ArgumentError unless entity_to.is_a?(@entity_to.class)
        self.class.map_entity(@easy_entity_attribute_maps, @entity_from, entity_to)
      end

      def entity
        @entity_to
      end

      alias_method :mapped, :entity
      alias_method :mapped_entity, :entity

      def entity_attributes
        attrs = entity.attributes.select { |k, v| k.in?(@easy_entity_attribute_maps.map(&:entity_to_attribute)) }
        if entity.respond_to?(:custom_field_values)
          attrs['custom_field_values'] = entity.custom_field_values.inject({}) { |mem, var| mem[var.custom_field_id] = var.value; mem }
        end

        attrs
      end

      def inspect
        "<EasyEntityAttributeMapper entity_from=#{@entity_from.class.name}##{@entity_from.id} entity_to=#{@entity_to.class.name} available_maps=#{@easy_entity_attribute_maps.count} >"
      end

    end

  end
end
