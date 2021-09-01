module Exports
  require 'rubyXL'

  class ReArtifactProperties
    attr_reader :scope, :workbook

    ATTRIBUTES = %w[
      id
      artifact_type
      project_id
      parent_id
      name
      responsible_id
      status
      description
      acceptance_criteria
      issue_ids
      dependency_ids
      conflict_ids
    ]

    def initialize(scope)
      @scope    = scope
      @workbook = RubyXL::Workbook.new
    end

    def run
      worksheet = workbook[0]

      attribute_names.each_with_index do |name, index|
        worksheet.add_cell(0, index, name)
      end

      scope.each_with_index do |object, row_index|
        attribute_names.each_with_index do |name, column_index|
          worksheet.add_cell(row_index.next, column_index, attribute(object, name))
        end
      end
    end

    def to_stream
      workbook.stream
    end

    private

    def attribute_names
      ATTRIBUTES + ReArtifactPropertiesCustomField.pluck('custom_fields.name')
    end

    def attribute(object, name)
      if object.respond_to?(name)
        to_s(object.send(name))
      else
        object.custom_field_values.detect do |custom_field_value|
          custom_field_value.custom_field.name == name
        end.try(:value)
      end
    end

    def to_s(value)
      value.is_a?(Array) ? value.join(',') : value.try(:to_s)
    end
  end
end