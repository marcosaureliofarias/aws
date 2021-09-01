  module EasySwagger
    class EasyAttendanceActivity
      include EasySwagger::BaseModel
      swagger_me

      shared_scheme do
        property 'name', type: 'string'
        property 'position', type: 'integer'
        property 'at_work', type: 'boolean'
        property 'is_default', type: 'boolean'
        property 'internal_name', type: 'string'
        property 'non_deletable', type: 'boolean'

        timestamps

        property 'project_mapping', type: 'boolean'

        relation 'mapped_project', 'mapped_time_entry_activity'

        property 'mail', type: 'string' do
          key :description, ''
          key :format, 'datetime'
        end

        property 'color_schema' do
          key :enum, 0.upto(EasyExtensions::EasyProjectSettings.easy_color_schemes_count).map { |schema_number| "scheme-#{schema_number}" }
        end

        property 'approval_required', type: 'boolean'
        property 'use_specify_time', type: 'boolean'
        property 'system_activity', type: 'boolean'
      end

      response_schema do
      end
    end
  end
