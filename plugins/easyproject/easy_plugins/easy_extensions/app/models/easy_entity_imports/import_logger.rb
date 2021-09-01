module EasyEntityImports
  class ImportLogger

    attr_reader :log

    def initialize
      init_log
    end

    def init_log
      @log ||= {}
    end

    def init_log_for(*entity_klasses)
      init_log
      entity_klasses.each do |klass|
        entities_key       = klass.name.underscore.pluralize.to_sym
        @log[entities_key] = { created: {}, mapped: {}, warnings: {}, errors: {} } unless @log[entities_key]
      end
    end

    def log_entity_creation(entity, key = nil)
      log_event(entity, :created, key)
    end

    def log_entity_mapping(entity, key = nil)
      log_event(entity, :mapped, key)
    end

    def log_entity_warning(entity, key = nil, message = nil, multiple = false)
      log_event(entity, :warnings, key, message, multiple)
    end

    def log_entity_error(entity, key = nil, message = nil, multiple = false)
      key      = key || entity.try(:id) || :general
      multiple = multiple || key == :general
      log_event(entity, :errors, key, message, multiple)
    end

    def log_event(entity, group, key = nil, message = nil, multiple = false)
      return unless entity
      key         = key || entity.id
      entity_type = entity.class.name.underscore.pluralize.to_sym
      init_log_for(entity.class) unless @log[entity_type]
      if multiple
        @log[entity_type][group][key] ||= []
        @log[entity_type][group][key] << message
      else
        @log[entity_type][group][key] = message || entity
      end
    end

    def log_fatal_error(error_message)
      @log[:fatal_error] = error_message
    end

    def get_errors_for(entity_type, key)
      (@log[entity_type] && @log[entity_type][:errors][key]) || []
    end

  end
end
