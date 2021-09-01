Rys::Patcher.add('UsersController') do

  apply_if_plugins :easy_extensions

  included do
    before_action :extended_users_context_menu_find_users, only: [:add_users_to_group, :bulk_calendar_to_user, :bulk_generate_passwords, :bulk_next_login_passwords, :bulk_update_page_template]
    before_action :find_optional_custom_field_group, only: [:edit, :update]

    accept_api_auth_actions << :add_users_to_group
  end

  instance_methods(feature: 'custom_field_values_defaults') do

    def bulk_update
      bulk_generate_passwords if params[:generate_password]
      bulk_next_login_passwords if params[:generate_next_login_password]
      update_calendars if params[:calendar_id]
      update_page_templates if params[:page_template_id]

      super
    end

  end

  instance_methods do

    def add_users_to_group
      @group = Group.find_by(id: params[:user][:group_id].to_i)
      users = @users.not_in_group(@group).to_a
      @group.users << users

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default users_path
        }
        format.api {
          if users.any?
            render_api_ok
          else
            render_api_errors "#{l(:label_user)} #{l('activerecord.errors.messages.invalid')}"
          end
        }
      end
    end

    def bulk_calendar_to_user
      update_calendars

      redirect_back_or_default users_path
    end

    def bulk_generate_passwords
      @users.each do |user|
        user.generate_password = true
        if user.save && user.active? && user != User.current
          Mailer.deliver_account_information(user, user.password)
        end
      end

      redirect_back_or_default users_path unless params[:generate_password]
    end

    def bulk_next_login_passwords
      @users.update_all(must_change_passwd: true)

      redirect_back_or_default users_path unless params[:generate_next_login_password]
    end

    def bulk_update_page_template
      update_page_templates

      redirect_back_or_default users_path
    end

    private

    def find_optional_custom_field_group
      return unless params[:tab].present? && params[:tab].start_with?('easy_group')

      @custom_field_group = EasyCustomFieldGroup.find_by(name: params[:tab].sub('easy_group_', ''))
    end

    def extended_users_context_menu_find_users(logged = true)
      if params[:ids]
        @users = User.where(id: params[:ids])
        @users = @users.logged if logged
      end
    end

    def update_calendars
      calendar = EasyUserWorkingTimeCalendar.find_by(id: params[:calendar_id])
      return unless calendar

      EasyUserWorkingTimeCalendar.where(user_id: params[:ids]).update_all(parent_id: calendar.id)
    end

    def update_page_templates
      page_template = EasyPageTemplate.find_by(id: params[:page_template_id])
      return unless page_template

      @users.each do |user|
        unless params[:page_template_id].blank?
          begin
            EasyPageZoneModule.create_from_page_template(page_template, user.id)
          rescue ActiveRecord::RecordNotFound
          end
        end
      end
    end

  end
end
