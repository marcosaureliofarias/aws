module Imports
  require 'roo'

  class ReArtifactProperties
    attr_reader :file_path, :errors

    def initialize(file_path)
      @file_path = file_path
      @errors = []
    end

    def run
      if rows.empty?
        errors << [0, I18n.t(:error_can_not_read_import_file)]
        return
      end

      rows.each.with_index(1) do |row, index|
        object = ReArtifactPropertiesObject.new(row.with_indifferent_access)
        if object.valid?
          object.save
        else
          errors << [index, object.errors]
        end
      end
    end

    def error_message
      return errors if errors.is_a?(String)
      errors.map { |error| "row #{error[0]}. - #{error[1]}" }.join(', ')
    end

    def valid?
      !errors.is_a?(String) && errors.empty?
    end

    def rows
      return [] if sheet.first_row.nil?

      sheet.parse(header_search: sheet.first.compact)
    end

    def first_sheet
      attachment.sheets.first
    end

    def sheet
      attachment.sheet(first_sheet)
    end

    def attachment
      @attachment ||= begin
        Roo::Spreadsheet.open(file_path)
      rescue ArgumentError
        @errors = I18n.t(:re_artifact_properties_import_invalid_extension)
        nil
      end
    end
  end

  class ReArtifactPropertiesObject < ReBase
    ATTRIBUTES = %w[
      artifact_type
      project
      parent
      name
      responsible_id
      re_status
      description
      acceptance_criteria
    ].freeze

    REQUIRED_ATTRIBUTES = %w[
      artifact_type
      project
      name
    ].freeze

    def initialize(row)
      @row = row
      @object = ::ReArtifactProperties.find_or_initialize_by(id: row[:id])
      object.assign_attributes(attributes)
    end

    def save
      object.save
      return unless object.persisted?

      create_re_realizations!
      create_dependency_relations!
      create_conflict_relations!
    end

    def id
      row[:id]
    end

    def artifact_type
      row[:artifact_type]
    end

    def name
      row[:name]
    end

    def responsible_id
      row[:responsible_id]
    end

    def description
      row[:description]
    end

    def acceptance_criteria
      row[:acceptance_criteria]
    end

    def re_status
      ReStatus.find_by(label: row[:status], project: project)
    end

    def project
      @project ||= Project.find_by(id: row[:project_id])
    end

    def parent
      @parent ||=
        if row[:parent_id].present? && ::ReArtifactProperties.exists?(id: row[:parent_id])
          ::ReArtifactProperties.find_by(id: row[:parent_id])
        else
          ::ReArtifactProperties.find_by(project: project, artifact_type: 'Project')
        end

      object == @parent ? nil : @parent
    end

    def create_re_realizations!
      object.re_realizations.destroy_all

      split_by_comma(row[:issue_ids]).map do |issue_id|
        next unless Issue.exists?(id: issue_id)

        object.re_realizations.create(issue_id: issue_id)
      end
    end

    def create_dependency_relations!
      object.dependency_relations.destroy_all

      split_by_comma(row[:dependency_ids]).each do |sink_id|
        next if sink_id == id || !::ReArtifactProperties.exists?(id: sink_id)

        object.dependency_relations.create(sink_id: sink_id)
      end
    end

    def create_conflict_relations!
      object.conflict_relations.destroy_all

      split_by_comma(row[:conflict_ids]).each do |sink_id|
        next if sink_id == id || !::ReArtifactProperties.exists?(id: sink_id)

        object.conflict_relations.create(sink_id: sink_id)
      end
    end
  end
end
