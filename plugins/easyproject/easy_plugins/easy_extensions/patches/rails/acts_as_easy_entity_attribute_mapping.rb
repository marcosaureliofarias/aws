module EasyPatch
  module ActsAsEasyEntityAttributeMapping

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_easy_entity_attribute_map(options = {})
        return if self.included_modules.include?(EasyPatch::ActsAsEasyEntityAttributeMapping::ActsAsEasyEntityAttributeMappingMethods)

        if self.respond_to?(:safe_attributes)
          safe_attributes 'easy_entity_attribute_map_from'
        end


        send(:include, EasyPatch::ActsAsEasyEntityAttributeMapping::ActsAsEasyEntityAttributeMappingMethods)
      end

    end

    module ActsAsEasyEntityAttributeMappingMethods

      def self.included(base)
        base.class_eval do

          def easy_entity_attribute_map_from=(string)
            _class, _id     = string.split('#')
            entity_from     = _class.constantize.find(_id)
            x               = EasyExtensions::EasyEntityAttributeMappings::Mapper.new(entity_from, self.class)
            mapped          = x.map_entity
            self.attributes = mapped.attributes
            if self.respond_to?(:custom_field_values)
              self.custom_field_values = mapped.custom_field_values.inject({}) { |mem, var| mem[var.custom_field_id] = var.value; mem }
            end
          end

        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsEasyEntityAttributeMapping'
