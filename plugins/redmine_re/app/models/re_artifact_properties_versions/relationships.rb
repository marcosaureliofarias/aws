module ReArtifactPropertiesVersions
  module Relationships
    extend ActiveSupport::Concern

    included do
      def sink_relationships
        relationships_as_sink.pluck(:source_id, :relation_type)
      end

      def source_relationships
        relationships_as_source.pluck(:sink_id, :relation_type)
      end

      def sink_relationships=(array)
        array.each { |item| relationships_as_sink.find_or_create_by(source_id: find_or_recover_artifact(item[0]).id, relation_type: item[1]) }
      end

      def source_relationships=(array)
        array.each { |item| relationships_as_source.find_or_create_by(sink_id: find_or_recover_artifact(item[0]).id, relation_type: item[1]) }
      end

      def find_or_recover_artifact(id)
        artifact = ReArtifactProperties.with_deleted.find(id)
        artifact.recover if artifact.deleted?
        artifact
      end

      def custom_fields
        custom_field_attribute_ids.map do |id|
          { id => custom_field_value(id) }
        end
      end

      def custom_fields=(array)
        return if array.empty?

        assign_attributes(custom_field_values: array.inject(:merge))
      end

      def custom_field_value(id)
        custom_field_values.detect do |custom_field_value|
          custom_field_value.custom_field.id == id
        end.try(:value)
      end

      def custom_field_attribute_ids
        ReArtifactPropertiesCustomField.pluck('custom_fields.id')
      end
    end
  end
end