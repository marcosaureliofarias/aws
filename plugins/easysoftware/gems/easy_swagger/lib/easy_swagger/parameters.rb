module EasySwagger
  module Parameters
    def self.extended(base)

      base.parameter do
        key :name, "format"
        key :description, "specify format of response"
        key :in, "path"
        key :required, true
        schema do
          key :type, "string"
          key :enum, %w[json xml]
        end
      end

    end
  end

end