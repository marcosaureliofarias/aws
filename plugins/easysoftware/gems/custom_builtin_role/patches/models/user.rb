Rys::Patcher.add('User') do
  apply_if_plugins :easy_extensions

  instance_methods do

    def builtin_role
      if Rys::Feature.active?('custom_builtin_role')
        @custom_builtin_role ||= easy_user_type&.builtin_role || super
      else
        super
      end
    end

    def easy_project_ids_by_role(options = {})
      if Rys::Feature.active?('custom_builtin_role')
        @easy_project_ids_by_role_with_builtin ||= begin
          project_ids_by_role = super

          builtin_role = easy_user_type&.builtin_role

          if builtin_role
            if !project_ids_by_role.has_key?(builtin_role)
              project_ids_by_role[builtin_role] = []
            end

            project_ids_by_role[builtin_role].concat(Project.where.not(status: Project::STATUS_ARCHIVED).ids)
            project_ids_by_role[builtin_role].uniq!
          end

          project_ids_by_role
        end
      else
        super
      end
    end

    def roles_for_project(project)
      roles = super

      if Rys::Feature.active?('custom_builtin_role') && project&.active? && easy_user_type&.builtin_role
        # To avoid rewriting an existed Array
        roles += [easy_user_type.builtin_role]
      end

      roles
    end

    def managed_roles(project)
      roles = super

      if Rys::Feature.active?('custom_builtin_role') && project&.active? && easy_user_type&.builtin_role
        if builtin_role.has_permission?(:manage_members)
          if builtin_role.all_roles_managed?
            roles += Role.givable.to_a
          else
            roles += builtin_role.managed_roles.to_a
          end
        end
      end

      roles
    end

    def all_roles
      @all_roles_with_builtin ||= begin
        roles = super

        if Rys::Feature.active?('custom_builtin_role') && easy_user_type&.builtin_role
          roles += [easy_user_type.builtin_role]
        end

        roles
      end
    end

    def membership(project)
      if Rys::Feature.active?('custom_builtin_role')
        super || (MemberWithBuiltinRole.new(principal: self, project: project, role: easy_user_type.builtin_role) if easy_user_type&.builtin_role.present?)
      else
        super
      end
    end

    def reload(*args)
      if Rys::Feature.active?('custom_builtin_role')
        @custom_builtin_role                   = nil
        @easy_project_ids_by_role_with_builtin = nil
        @all_roles_with_builtin                = nil
      end
      super
    end

  end

end
