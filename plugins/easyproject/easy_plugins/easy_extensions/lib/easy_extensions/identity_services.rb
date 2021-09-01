require 'easy_extensions/identity_service_configuration'

module EasyExtensions
  class IdentityServices

    cattr_accessor :_static_ids
    cattr_accessor :_dynamic_ids
    #thread_cattr_accessor :_registered

    class << self

      def register(name_or_proc, entity = nil, &block)
        case name_or_proc
        when Proc
          register_dynamic(name_or_proc, &block)
        when Symbol, String
          register_static(name_or_proc.to_s, entity, &block)
        end
      end

      def configure(entity = nil, &block)
        config = EasyExtensions::IdentityServiceConfiguration.new

        yield config, entity if block_given?

        config
      end

      def register_static(name, entity = nil, &block)
        self._static_ids       ||= {}
        self._static_ids[name] = configure(entity, &block)
      end

      def register_dynamic(proc_array, &block)
        self._dynamic_ids ||= []
        self._dynamic_ids << [proc_array, block]
      end

      def actives
        registered.select { |_, idp| idp.active? }
      end

      def registered
        # return self._registered if !self._registered.nil?
        #
        # self._static_ids  ||= {}
        # self._dynamic_ids ||= []
        # self._registered  = self._static_ids
        #
        # self._dynamic_ids.each do |item|
        #   entities = item[0].call
        #   entities.each do |entity|
        #     self._registered["#{entity.class.name.underscore}_#{entity.id}"] = configure(entity, &item[1])
        #   end
        # end
        #
        # self._registered

        self._static_ids  ||= {}
        self._dynamic_ids ||= []
        _registered       = self._static_ids

        self._dynamic_ids.each do |item|
          entities = item[0].call
          entities.each do |entity|
            _registered["#{entity.class.name.underscore}_#{entity.id}"] = configure(entity, &item[1])
          end
        end

        _registered
      end

    end
  end
end
