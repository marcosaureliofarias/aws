module EasySwagger
  class EasyGanttResourcesAdvanceHoursLimit
    include EasySwagger::BaseModel
    swagger_me

    response_schema "EasyGanttResourcesAdvanceHoursLimit" do
      key :title, 'EasyGanttResourcesAdvanceHoursLimit'
      key :type, 'number'
      key :format, 'float'
    end
  end
end