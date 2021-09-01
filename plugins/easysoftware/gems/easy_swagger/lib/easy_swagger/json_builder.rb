module EasySwagger
  class JsonBuilder < Redmine::Views::Builders::Json
    def initialize
      @struct = [{}]
    end
  end
end
