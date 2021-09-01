module EasyExtensions
  class EasyTag

    class_attribute :registered_taggables
    self.registered_taggables = {}

    def self.register(model, options = {})
      opt                              = options.dup
      opt[:referenced_collection_name] ||= model.base_class.to_s.pluralize.underscore

      registered_taggables[model.base_class.to_s] ||= opt

      ActsAsTaggableOn::Tag.class_eval do
        has_many opt[:referenced_collection_name].to_sym, through: :taggings, source: :taggable, source_type: model.base_class.to_s, class_name: model.to_s
      end
    end

    def self.all_for(tag, &block)
      used_on = ActsAsTaggableOn::Tagging.where(:tag_id => tag).distinct.pluck(:taggable_type)

      used_on.each do |model_name|
        begin
          yield model_name.constantize, registered_taggables[model_name] || {}
        rescue NameError # in case the taggable entity's plugin is disabled
          next
        end
      end
    end

    def self.easy_query_class(referenced_entity_type, options)
      options ||= {}

      if options[:easy_query_class].nil?
        easy_query_class_name = referenced_entity_type.name + 'Query'
        easy_query_class_name = ('Easy' + easy_query_class_name) if !easy_query_class_name.start_with?('Easy')

        easy_query_class = easy_query_class_name.safe_constantize
      elsif options[:easy_query_class].is_a?(String)
        easy_query_class = options[:easy_query_class].safe_constantize
      else
        easy_query_class = options[:easy_query_class]
      end
      easy_query_class
    end

  end
end
