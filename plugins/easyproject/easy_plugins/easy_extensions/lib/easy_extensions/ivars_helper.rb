module EasyExtensions
  module IvarsHelper
    class << self
      def yaml_likes(attributes)
        attributes.map { |a| "#{a} LIKE '---%'" }.join(' OR ')
      end

      def detect_ivars(klass, attributes)
        klass.unscoped.where(yaml_likes(attributes)).find_each(batch_size: 500) do |entity|
          attributes.each do |attribute|
            value = entity.read_attribute_before_type_cast(attribute)
            if value && (value.to_s.include?('ivars') || value.to_s.include?('ActionController::Parameters'))
              puts "IVARs detected! #{klass} => #{attribute}" if value.to_s.include?('ivars')
              fix_ivars!(klass, attribute)
            end
          end
        end
      end

      def convert_to_json(klass, attributes, detect_ivars = true)
        detect_ivars(klass, attributes) if detect_ivars

        klass.unscoped.where(yaml_likes(attributes)).find_each(batch_size: 100) do |entity|
          attributes.each do |attribute|
            raw_value = entity.read_attribute_before_type_cast(attribute)
            if raw_value
              converted = begin
                YAML.load(raw_value)
              rescue StandardError => e
                yaml_error(raw_value, entity, attribute, e.message)
              end

              entity.class.base_class.unscoped.where(entity.class.primary_key => entity.send(entity.class.primary_key)).update_all(attribute => converted)
            end
          end
        end
      end

      def yaml_error(raw_value, entity, attribute, message)
        msg = ["An error occurred when loading value: #{raw_value} - table: #{entity.class.table_name}, id: #{entity.send(entity.class.primary_key)}, attribute: #{attribute}"]
        msg << 'Database data may be corrupted, fix or remove these entries manually'
        msg << "error: #{message}"
        msg.join("\n")
      end

      def fix_ivars!(klass, attribute)
        klass.unscoped.where(yaml_likes([attribute])).find_each(batch_size: 100) do |entity|
          attribute_value = begin
            raw_value = entity.read_attribute_before_type_cast(attribute)
            YAML.load(raw_value)
          rescue StandardError => e
            raise yaml_error(raw_value, entity, attribute, e.message)
          end
          original_attribute_value = attribute_value.deep_dup
          ihash!(attribute_value)
          if attribute_value != original_attribute_value
            entity.class.base_class.unscoped.where(entity.class.primary_key => entity.send(entity.class.primary_key)).update_all(attribute => attribute_value)
          end
          if (attribute_value = deep_convert_parameters(attribute_value))
            entity.class.base_class.unscoped.where(entity.class.primary_key => entity.send(entity.class.primary_key)).update_all(attribute => attribute_value)
          end
        end
      end

      def ihash!(h)
        merge = nil
        h.delete('ivars')
        h.each_pair do |k, v|
          if v.is_a?(Hash)
            if k == 'elements'
              merge = v
            else
              ihash!(v)
            end
          else
            # good
          end
        end
        if merge
          h.merge!(merge)
          h.delete('elements')
          ihash!(h)
        end
        h
      end

      def deep_convert_parameters(h)
        changed = false
        h.each_pair do |k, v|
          if v.is_a?(Hash)
            if deep_convert_parameters(v)
              changed = true
            end
          end
          if v.is_a?(ActionController::Parameters)
            h[k]    = v.to_unsafe_hash
            changed = true
          else
            # good
          end
        end
        if h.is_a?(ActionController::Parameters)
          h       = h.to_unsafe_hash
          changed = true
        else
          h
        end
        changed ? h : false
      end
    end
  end
end