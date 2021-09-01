module EasyGanttResources
  module EasySwaggerUserPatch
    
    def self.included(base)
      base.class_eval do
        
        easy_swagger_schema 'UserApiRequest' do
          property 'easy_gantt_resources_estimated_ratio' do
            key :type, 'number'
            key :format, 'float'
            key :description, '(available if the user is allowed to manage Easy Gantt Resource user attributes)'
            key :example, '1.0'
          end

          property 'easy_gantt_resources_hours_limit' do
            key :type, 'number'
            key :format, 'float'
            key :description, '(available if the user is allowed to manage Easy Gantt Resource user attributes)'
            key :example, '1.0'
          end

          property 'easy_gantt_resources_advance_hours_limits' do
            key :type, 'array'
            key :description, 'Should contain 7 values, one per each day of the week. (Available if the user is allowed to manage Easy Gantt Resource user attributes.)'
            key :example, [8.0, 8.0, 8.0, 8.0, 8.0, 0.0, 0.0]
            key :xml, wrapped: true
            items ref: EasySwagger::EasyGanttResourcesAdvanceHoursLimit
          end
        end

        easy_swagger_schema 'UserApiResponse' do
          property 'easy_gantt_resources_estimated_ratio' do
            key :type, 'number'
            key :format, 'float'
            key :description, '(available if the user is allowed to manage Easy Gantt Resource user attributes)'
            key :example, '1.0'
          end

          property 'easy_gantt_resources_hours_limit', type: 'string' do
            key :type, 'number'
            key :format, 'float'
            key :description, '(available if the user is allowed to manage Easy Gantt Resource user attributes)'
            key :example, '1.0'
          end

          property 'easy_gantt_resources_advance_hours_limits' do
            key :type, 'array'
            key :xml, wrapped: true
            key :description, 'Should contain 7 values, one per each day of the week. (Available if the user is allowed to manage Easy Gantt Resource user attributes.)'
            key :example, [8.0, 8.0, 8.0, 8.0, 8.0, 0.0, 0.0]
            items ref: EasySwagger::EasyGanttResourcesAdvanceHoursLimit
          end
        end

      end
    end

  end
end