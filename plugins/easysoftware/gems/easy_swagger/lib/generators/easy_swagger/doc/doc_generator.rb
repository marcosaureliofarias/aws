module EasySwagger
  class DocGenerator < Rails::Generators::NamedBase

    def create_model_file
      invoke "easy_swagger:model", ARGV
    end

    def create_controller_file
      invoke "easy_swagger:controller", ARGV
    end

    private

    # @return [ActiveRecord::Base]
    def model
      class_name.safe_constantize
    end

    # @return [Array]
    def model_columns
      return [] unless model

      skip = %w[id created_on updated_on created_at updated_at]
      @columns = []
      model.columns.each do |column|
        next if skip.include? column.name

        @columns << SwaggerGeneratorAttribute.new(column, example_entity)
      end
      @columns
    end

    def model_column_names
      (model&.columns || []).map(&:name)
    end

    # Little piggy - return `:legacy` if columns include legacy timestamp. If not return true if include normal...
    # @return [Symbol, TrueClass, FalseClass]
    def timestamps?
      if (model_column_names & %w[created_on updated_on]).any?
        :legacy
      else
        (model_column_names & %w[created_at updated_at]).any?
      end
    end

    # is there `acts_as_customizable` on Class ?
    # @return [Boolean]
    def custom_fields?
      model.included_modules.include?(Redmine::Acts::Customizable::InstanceMethods)
    end

    # This is very-very experimental, security issue, ugly, piggy thing
    def example_entity
      @example_entity ||= model&.last
    end

    class SwaggerGeneratorAttribute < SimpleDelegator

      # @param [ActiveRecord::ConnectionAdapters::Column] obj
      # @param [ActiveRecord::Base] example object
      def initialize(obj, example = nil)
        @example_object = example
        super(obj)
      end

      def type
        case super
        when :text, :datetime, :date
          "string"
        when :float, :decimal
          "number"
        else
          super.to_s
        end
      end

      def format
        return @format if defined? @format

        @format ||= case __getobj__.type
                    when :float
                      "float"
                    when :datetime
                      "date-time"
                    when :date
                      "date"
                    end
      end

      def example
        return nil if type == "boolean"

        @example_object.try(name)
      end

      def read_only?
        ::User.current.as_admin do
          return !(@example_object&.safe_attribute_names || []).include?(name)
        end
      end

    end
  end

  class Model < DocGenerator
    source_root File.expand_path('templates', __dir__)


    def create_doc_file
      template 'model.rb', File.join('api/easy_swagger', "#{file_name}.rb")
    end
  end

  class Controller < DocGenerator
    source_root File.expand_path('templates', __dir__)

    def create_doc_file
      template 'controller.rb', File.join('api/easy_swagger', "#{plural_file_name}_controller.rb")
    end
  end
end
