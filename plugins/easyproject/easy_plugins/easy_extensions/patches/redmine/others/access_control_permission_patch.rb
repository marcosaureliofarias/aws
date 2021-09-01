module EasyPatch
  module AccessControlPermissionPatch

    def self.included(base)
      base.prepend(InstanceMethods)

      base.class_eval do

        attr_accessor :acts_as_admin, :acts_as_admin_proc, :depends_on, :easy_category

        def add_actions(hash)
          hash.each do |controller, actions|
            if actions.is_a? Array
              @actions << actions.collect { |action| "#{controller}/#{action}" }
            else
              @actions << "#{controller}/#{actions}"
            end
          end
          @actions.flatten!
        end

        def permission_flags
          f = []
          f << 'r' if read?
          f << 'p' if public?
          f << 'm' if require_member?
          f << 'l' if require_loggedin?
          f
        end

        def acts_as_admin?(user = nil)
          if acts_as_admin_proc.is_a?(Proc)
            acts_as_admin_proc.call(user)
          else
            @acts_as_admin == true
          end
        end

        def set_options(options = {})
          @public     = !!options[:public] if options.key?(:public)
          @read       = !!options[:read] if options.key?(:read)
          @require    = options[:require] if options.key?(:require)
          @global     = !!options[:global] if options.key?(:global)
          @depends_on = Array(options[:depends_on]) if options.key?(:depends_on)
        end

        def global?
          @global
        end

      end
    end

    module InstanceMethods

      def initialize(name, hash, options)
        super
        @global        = !!options[:global]
        @easy_category = options[:easy_category] || options[:project_module]
        @depends_on    = Array(options[:depends_on]) if options.key?(:depends_on)
      end

    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::AccessControl::Permission', 'EasyPatch::AccessControlPermissionPatch'
