module EasySwagger
  # Output as a regular Hash
  class HashBuilder < Redmine::Views::Builders::Structure
    def initialize
      @struct = [{}]
    end

    def output
      @struct.first.to_h
    end
  end
end
