module EasyPatch
  module RolesHelperPatch
    def self.included(base) # :nodoc:

      base.class_eval do

        def sorted_permission_keys(permissions)
          permissions.keys.sort_by do |x|
            case x.to_s
            when ''
              ''
            when 'easy_other_permissions'
              'zzzzzzzz'
            else
              l_or_humanize(x, :prefix => 'project_module_')
            end
          end
        end

        def group_by_global_and_module(permissions)
          per = {}
          per['global'], per['project'] = permissions.partition{ |p| p.global? }
          per.each do |group, perms|
            per[group] = perms.group_by { |p| (p.easy_category || p.project_module).to_s }
          end
        end

        def module_perm_disabled?(mod)
          if EasyExtensions::EasyProjectSettings.disabled_features[:permissions].key?(mod)
            EasyExtensions::EasyProjectSettings.disabled_features[:permissions][mod] == :all
          else
            false
          end
        end

        def permission_disabled?(mod, permission)
          if EasyExtensions::EasyProjectSettings.disabled_features[:permissions].key?(mod)
            EasyExtensions::EasyProjectSettings.disabled_features[:permissions][mod].include?(permission.name)
          else
            false
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'RolesHelper', 'EasyPatch::RolesHelperPatch'
