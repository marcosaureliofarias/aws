require 'easy_extensions/identity_provider_configuration'

module EasyExtensions
  class IdentityProviders

    cattr_accessor :_static_idp
    cattr_accessor :_dynamic_idp
    #thread_cattr_accessor :_registered

    class << self

      def selected
        EasySetting.value('selected_identity_provider_name')
      end

      def register(name_or_proc, entity = nil, &block)
        case name_or_proc
        when Proc
          register_dynamic(name_or_proc, &block)
        when Symbol, String
          register_static(name_or_proc.to_s, entity, &block)
        end
      end

      def configure(entity = nil, &block)
        config = EasyExtensions::IdentityProviderConfiguration.new

        yield config, entity if block_given?

        config
      end

      def register_static(name, entity = nil, &block)
        self._static_idp       ||= {}
        self._static_idp[name] = configure(entity, &block)
      end

      def register_dynamic(proc_array, &block)
        self._dynamic_idp ||= []
        self._dynamic_idp << [proc_array, block]
      end

      def actives
        registered.select { |_, idp| idp.active? }
      end

      def checked
        registered.select { |_, idp| idp.active? && idp.checked? }
      end

      def current
        if (idp = registered[selected]) && idp.active?
          idp
        end
      end

      def registered
        # return self._registered if !self._registered.nil?
        #
        # self._static_idp  ||= {}
        # self._dynamic_idp ||= []
        # self._registered  = self._static_idp
        #
        # self._dynamic_idp.each do |item|
        #   entities = item[0].call
        #   entities.each do |entity|
        #     self._registered["#{entity.class.name.underscore}_#{entity.id}"] = configure(entity, &item[1])
        #   end
        # end
        #
        # self._registered

        self._static_idp  ||= {}
        self._dynamic_idp ||= []
        _registered       = self._static_idp

        self._dynamic_idp.each do |item|
          entities = item[0].call
          entities.each do |entity|
            _registered["#{entity.class.name.underscore}_#{entity.id}"] = configure(entity, &item[1])
          end
        end

        _registered
      end

      def registered_with_login_button
        registered.select { |k, v| v.login_button? }
      end

    end
  end
end
