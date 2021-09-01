module EasyPatch
  module AccessControlPatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do

        class << self

          alias_method_chain :available_project_modules, :easy_extensions

          def update_permission(name, hash, options = {})
            if p = permission(name)
              p.add_actions(hash) unless hash.blank?
              p.set_options(options) unless options.blank?
            end
          end

          def permission_acts_as_admin(name, proc = nil)
            if p = permission(name)
              p.acts_as_admin      = true
              p.acts_as_admin_proc = proc
            end
          end

          def remove_permission(name)
            if p = permission(name)
              @permissions.delete(p)
            end
          end

          def disabled_rys_modules
            modules = []
            @permissions.each do |p|
              next if !p.rys_feature ||
                !p.project_module ||
                modules.include?(p.project_module) ||
                is_regular_plugin?(p)

              unless p.rys_feature.all?{|f| Rys::Feature.active?(f)}
                modules << p.project_module
              end
            end
            modules
          end

          def is_regular_plugin?(p)
            @permissions.any? do |perm|
              !perm.rys_feature && p.project_module == perm.project_module
            end
          end
        end

      end
    end

    module ClassMethods

      def available_project_modules_with_easy_extensions
        modules = available_project_modules_without_easy_extensions - EasyExtensions::EasyProjectSettings.disabled_features[:modules].collect(&:to_sym)
        modules -= disabled_rys_modules if Object.const_defined?(:Rys)
        modules
      end

    end


  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::AccessControl', 'EasyPatch::AccessControlPatch'
