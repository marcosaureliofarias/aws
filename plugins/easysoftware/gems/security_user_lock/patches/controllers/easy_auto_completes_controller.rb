Rys::Patcher.add('EasyAutoCompletesController') do

  apply_if_plugins :easy_extensions

  included do
    def admin_users
      @users = get_active_admin_users_scope(params[:term], EasySetting.value('easy_select_limit').to_i).to_a

      respond_to do |format|
        format.api { render template: 'easy_auto_completes/users_with_id', formats: [:api]
        }
      end
    end

    def get_active_admin_users_scope(term='', limit=nil)
      scope = get_active_users_scope(term, limit)
      scope = scope.admin
      scope
    end
  end


end
