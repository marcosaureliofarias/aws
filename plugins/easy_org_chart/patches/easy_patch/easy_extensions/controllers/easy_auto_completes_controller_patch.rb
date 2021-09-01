module EasyOrgChart
  module EasyAutoCompletesControllerPatch

    def self.included(base)

      base.class_eval do

        def all_supervisor_users_values
          @users = get_active_users_scope(params[:term], EasySetting.value('easy_select_limit').to_i)
          @users = @users.where(id: EasyOrgChart::Tree.supervisor_user_ids).to_a
          @additional_select_options = { "<< #{l(:label_me)} >>" => 'me' }

          respond_to do |format|
            format.api { render template: 'easy_auto_completes/users_with_id', formats: [:api], locals: { additional_select_options: @additional_select_options } }
          end
        end

      end
    end
  end
end

RedmineExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyOrgChart::EasyAutoCompletesControllerPatch'
