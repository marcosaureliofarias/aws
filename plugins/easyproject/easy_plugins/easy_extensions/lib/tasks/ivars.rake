require_relative '../easy_extensions/ivars_helper'

namespace :easyproject do
  desc <<-END_DESC
    Fix ivars

    Example:
      bundle exec rake easyproject:fixivars entity_type=EasyPageZoneModule attribute=settings RAILS_ENV=production
      bundle exec rake easyproject:fixivars RAILS_ENV=production
  END_DESC

  task :fixivars => :environment do
    if ENV['entity_type'].blank?
#      Dir.glob("#{Rails.root}/**/app/models/**/*.rb").each do |f|
#        begin
#          require f
#        rescue StandardError, LoadError
#        end
#      end

      models = ActiveRecord::Base.connection.tables.map do |model|
        model.capitalize.singularize.camelize
      end

      serialized_attributes = {}
      models.each do |model|
        klass = model.safe_constantize || model.sub('Easy', '').safe_constantize
        if klass
          klass_columns                = klass.column_names.select { |c| klass.type_for_attribute(c).is_a?(::ActiveRecord::Type::Serialized) }
          serialized_attributes[klass] = klass_columns unless klass_columns.empty?
        end
      end

      serialized_attributes.each do |klass, attributes|
        attributes.each do |attribute|
          EasyExtensions::IvarsHelper.fix_ivars!(klass, attribute)
        end
      end
    else
      entity_klass_name = ENV['entity_type'].to_s.classify
      entity_klass      = entity_klass_name.safe_constantize
      attribute         = ENV['attribute']

      fail "Error: entity_klass: #{entity_klass_name} not found!" unless entity_klass
      fail "Error: attribute: #{attribute} not found!" unless attribute

      EasyExtensions::IvarsHelper.fix_ivars!(entity_klass, attribute)
    end
  end
end
