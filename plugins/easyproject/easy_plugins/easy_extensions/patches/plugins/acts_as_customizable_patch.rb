module EasyPatch

  module ActsAsCustomizableInstanceMethodsPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :custom_fields=, :easy_extensions
        alias_method_chain :custom_field_values, :easy_extensions
        alias_method_chain :custom_field_values=, :easy_extensions
        alias_method_chain :visible_custom_field_values, :easy_extensions
        alias_method_chain :save_custom_field_values, :easy_extensions
        alias_method_chain :validate_custom_field_values, :easy_extensions
        alias_method_chain :reassign_custom_field_values, :easy_extensions

        attr_accessor :reassigning_values

        def custom_field_value_for(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          custom_field_values.detect { |v| v.custom_field_id == field_id }
        end

        def custom_field_casted_value(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          custom_field_values.detect { |v| v.custom_field_id == field_id }.try(:cast_value)
        end

        def sum_custom_field_values_on_entities(entities)
          cf_map = {}
          entities.sort_by { |e| e.respond_to?(:created_at) ? e.created_at : e.created_on }.each do |entity|
            entity.visible_custom_field_values.each do |cfv|
              if old_sum_cfv = cf_map[cfv.custom_field]
                if !cfv.value.blank?
                  if cfv.custom_field.field_format == 'list' && cfv.value.is_a?(Array) && cfv.custom_field.multiple?
                    old_sum_cfv.value = (old_sum_cfv.value + cfv.value).flatten.reject(&:blank?).uniq
                  else
                    old_sum_cfv.value = cfv.value
                  end
                end
              else
                new_sum_cfv              = cfv.dup
                new_sum_cfv.customized   = nil
                cf_map[cfv.custom_field] = new_sum_cfv
              end
            end
          end
          cf_map.values
        end

        def grouped_custom_field_values(values = [])
          grouped = values.group_by { |value| value.custom_field.easy_group }
          if grouped.size > 1
            without_group = grouped.delete(nil)
            grouped       = grouped.sort_by { |k, _| k.position }.to_h
            grouped[nil]  = without_group if without_group
          end
          grouped
        end

        def build_custom_values_for_save
          target_custom_values = []
          custom_field_values.each do |custom_field_value|
            if custom_field_value.value.is_a?(Array)
              custom_field_value.value.each do |v|
                target = custom_values.detect { |cv| cv.custom_field == custom_field_value.custom_field && cv.value == v }
                target ||= custom_values.build(customized: self, custom_field: custom_field_value.custom_field, value: v)
                target_custom_values << target
              end
            else
              target       = custom_values.detect { |cv| cv.custom_field == custom_field_value.custom_field }
              target       ||= custom_values.build(customized: self, custom_field: custom_field_value.custom_field)
              target.value = custom_field_value.value
              target_custom_values << target
            end
          end
          target_custom_values
        end

        def default_custom_field_value(cv)
          cv.value
        end

      end

    end

    module InstanceMethods

      def custom_fields_with_easy_extensions=(values)
        return unless values

        values_to_hash           = values.inject({}) do |hash, v|
          v = v.stringify_keys
          if v.has_key?('value')
            if !v['id'].blank?
              hash[v['id']] = v['value']
            elsif !v['internal_name'].blank?
              hash[v['internal_name']] = v['value']
            end
          end
          hash
        end
        self.custom_field_values = values_to_hash
      end

      def custom_field_values_with_easy_extensions
        @custom_field_values ||= available_custom_fields.collect do |field|
          x              = CustomFieldValue.new
          x.custom_field = field
          x.customized   = self
          if field.multiple?
            values = custom_values.select { |v| v.custom_field == field }
            if values.empty?
              values << custom_values.build(:customized => self, :custom_field => field)
            end
            x.instance_variable_set("@value", values.map { |cv| default_custom_field_value(cv) })
          else
            cv = custom_values.detect { |v| v.custom_field == field }
            cv ||= custom_values.build(:customized => self, :custom_field => field)
            x.instance_variable_set("@value", default_custom_field_value(cv))
          end
          x.value_was = x.value.dup if x.value
          x
        end
      end

      def custom_field_values_with_easy_extensions=(values)
        values = values.stringify_keys
        custom_field_values.each do |custom_field_value|

          id_key            = custom_field_value.custom_field_id.to_s
          internal_name_key = custom_field_value.custom_field.internal_name.to_s
          if values.has_key?(id_key) || values.has_key?(internal_name_key)
            value = values[id_key] || values[internal_name_key]
            if value.is_a?(Array)
              value = value.reject(&:blank?)
              unless @reassigning_values
                value.map! { |x| custom_field_value.custom_field.format.get_value_from_params(x) }
              end
              value.uniq!
              value << '' if value.empty?
            else
              unless @reassigning_values
                # EasyRating needs rating and description
                # Cannot be stored to value because of validation (int format)
                parameters = [value]
                parameters << id_key if custom_field_value.custom_field.field_format == 'easy_rating'
                value = custom_field_value.custom_field.format.get_value_from_params(*parameters)
              end
            end
            custom_field_value.value = value
          end
        end
        @custom_field_values_changed = true
      end

      def save_custom_field_values_with_easy_extensions
        self.custom_values = build_custom_values_for_save
        custom_values.each(&:save)
        # CustomValue.where(id: custom_values.reload.pluck(:id) - build_custom_values_for_save.map(&:id)).delete_all
        # build_custom_values_for_save.each(&:save!)
        @custom_field_values_changed = false
        true
      end

      def reassign_custom_field_values_with_easy_extensions
        @reassigning_values = true
        reassign_custom_field_values_without_easy_extensions
        @reassigning_values = false
      end

      def changed_for_autosave?
        super || custom_field_values_changed?
      end

      def visible_custom_field_values_with_easy_extensions
        visible_custom_field_values_without_easy_extensions.select { |cv| cv.custom_field&.visible_by?(nil, User.current) }
      end

      def validate_custom_field_values_with_easy_extensions
        custom_field_values.each(&:validate_value)
        custom_field_values.each(&:validate_value_with_custom_field_value)
      end

      def required_custom_field_values
        custom_field_values.select{ |c| c.custom_field.is_required? }
      end

    end

  end

  module ActsAsCustomizableClassMethodsPatch

    def self.included(base)
      base.include(ClassMethods)

      base.class_eval do

        alias_method_chain :acts_as_customizable, :easy_extensions

      end
    end

    module ClassMethods

      def acts_as_customizable_with_easy_extensions(options = {})
        acts_as_customizable_without_easy_extensions(options)

        has_one :easy_global_rating, as: :customized
      end

    end

  end

end
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Customizable::InstanceMethods', 'EasyPatch::ActsAsCustomizableInstanceMethodsPatch', :first => true
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Customizable::ClassMethods', 'EasyPatch::ActsAsCustomizableClassMethodsPatch', :first => true
