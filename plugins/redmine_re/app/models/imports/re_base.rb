module Imports
  class ReBase
    attr_reader :object, :row

    def valid?
      self.class::REQUIRED_ATTRIBUTES.all? { |method| respond_to?(method) && send(method).presence.present? } &&
        object.valid?
    end

    def errors
      object.errors.full_messages.join(', ')
    end

    def attributes
      Hash[ *self.class::ATTRIBUTES.map { |method_name| [method_name, send(method_name)] }.flatten(1) ]
        .merge(custom_field_attributes)
    end

    def split_by_comma(string)
      string.to_s.split(',')
    end

    def custom_field_attributes
      hash = {}
      hash[:custom_field_values] = {}

      ReArtifactPropertiesCustomField.pluck('custom_fields.id, custom_fields.name, custom_fields.multiple').each do |custom_field|
        value = row[custom_field[1]].to_s
        value = value.split(',').map(&:strip) if custom_field[2]

        hash[:custom_field_values][custom_field[0]] = value
      end

      hash
    end
  end
end