module ApiPrincipalsHelper
  def render_api_principal(api, principal)
    if principal.is_a?(User)
      render_api_user(api, principal)
    elsif principal.is_a?(Group)
      render_api_group(api, principal)
    end
  end

  def render_api_user(api, user)
    is_lesser_admin = User.current.easy_lesser_admin_for?(:users)
    api.user do
      api.id(user.id)
      api.login(user.login) if is_lesser_admin || (User.current == user)
      api.admin(user.admin?) if is_lesser_admin || (User.current == user)
      api.firstname(user.firstname)
      api.lastname(user.lastname)
      api.utc_offset((user.time_zone || Time.zone).utc_offset)
      api.mail(user.mail) if is_lesser_admin || !user.pref.hide_mail
      api.created_on(user.created_on)
      api.last_login_on(user.last_login_on)
      api.status(user.status) if is_lesser_admin
      api.easy_system_flag(user.easy_system_flag) if is_lesser_admin
      api.easy_external_id(user.easy_external_id) if is_lesser_admin
      api.easy_user_type(:id => user.easy_user_type.id, :name => user.easy_user_type.name) if is_lesser_admin && !user.easy_user_type.nil?
      api.easy_lesser_admin(user.easy_lesser_admin) if is_lesser_admin
      api.language user.language
      api.avatar_url avatar_url(user)
      if (uwtc = user.working_time_calendar)
        api.working_time_calendar id: uwtc.id, name: uwtc.name, default_working_hours: uwtc.default_working_hours, time_from: uwtc.time_from.strftime("%H:%M"), time_to: uwtc.time_to.strftime("%H:%M")
      end

      render_api_custom_values(user.visible_custom_field_values, api)

      api.array :groups do
        user.groups.each do |group|
          api.group :id => group.id, :name => group.name
        end
      end if is_lesser_admin && include_in_api_response?('groups')

      render_api_memberships(api, user.memberships.where(Project.visible_condition(User.current)).to_a) if include_in_api_response?('memberships')
      call_hook(:helper_render_api_user, { api: api, user: user })
    end
  end

  def render_api_group(api, group)
    api.group do
      api.id(group.id)
      api.name(group.lastname)
      api.builtin(group.builtin_type) if group.builtin_type
      if User.current.easy_lesser_admin_for?(:users)
        api.easy_system_flag(group.easy_system_flag)
        api.easy_external_id(group.easy_external_id)
      end
      api.created_on(group.created_on)

      render_api_custom_values(group.visible_custom_field_values, api)

      api.array :users do
        group.users.each do |user|
          api.user :id => user.id, :name => user.name
        end
      end if include_in_api_response?('users') && !group.builtin?

      render_api_memberships(api, group.memberships.where(Project.visible_condition(User.current)).to_a) if include_in_api_response?('memberships')
    end
  end

  def render_api_memberships(api, memberships)
    api.array :memberships do
      memberships.each do |membership|
        api.membership do
          api.id membership.id
          api.project :id => membership.project.id, :name => membership.project.name
          api.array :roles do
            membership.member_roles.each do |member_role|
              if member_role.role
                attrs             = { :id => member_role.role.id, :name => member_role.role.name }
                attrs[:inherited] = true if member_role.inherited_from.present?
                api.role attrs
              end
            end
          end
        end if membership.project
      end
    end
  end
end
