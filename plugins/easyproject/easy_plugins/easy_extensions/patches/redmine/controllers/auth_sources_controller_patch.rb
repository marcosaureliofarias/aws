module EasyPatch
  module AuthSourcesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        skip_before_action :require_admin, only: [:autocomplete_for_new_user]
        before_action :authorize_autocomplete, only: [:autocomplete_for_new_user]

        helper :users
        include UsersHelper

        def available_users
          return unless find_auth_source
          return render_404 unless @auth_source.respond_to?(:available_users)
          @available_users = @auth_source.available_users.map { |result| {
              'login'     => @auth_source.class.get_attr(result, @auth_source.attr_login),
              'firstname' => @auth_source.class.get_attr(result, @auth_source.attr_firstname),
              'lastname'  => @auth_source.class.get_attr(result, @auth_source.attr_lastname),
              'mail'      => @auth_source.class.get_attr(result, @auth_source.attr_mail),
              'dn'        => @auth_source.class.get_attr(result, 'dn')
          } }

          respond_to do |format|
            format.html
            format.json { render :json => @available_users.to_json }
          end
        end

        def available_attributes
          @auth_source = AuthSource.find_by(:id => params[:id])
          @auth_source ||= AuthSource.new_subclass_instance('AuthSourceLdap')
          return render_404 unless @auth_source && @auth_source.respond_to?(:available_attributes)
          @auth_source.safe_attributes = params[:auth_source] if params[:auth_source]

          render :json => @auth_source.available_attributes.to_json
        end

        def reload_easy_options_projects_and_roles
          @projects_and_roles = {}
          if !params['project_for_role'].blank? && !params['roles'].blank?
            @projects_and_roles[params['project_for_role']] = params['roles']
          end

          if params['auth_source'] && params['auth_source']['easy_options'] && params['auth_source']['easy_options']['projects_and_roles'].is_a?(Hash)
            @projects_and_roles.merge!(params['auth_source']['easy_options']['projects_and_roles'])
          end

          respond_to do |format|
            format.js
          end
        end

        def authorize_autocomplete
          require_admin_or_lesser_admin(:users)
        end

        alias_method_chain :destroy, :easy_extensions

      end
    end

    module InstanceMethods

      def destroy_with_easy_extensions
        if @auth_source.users.exists?
          if params[:auth_source_replacement]
            replacement = params[:auth_source_replacement].blank? ? nil : AuthSource.find(params[:auth_source_replacement])
            User.where(:auth_source_id => @auth_source.id).all.each do |user|
              user.auth_source = replacement
              user.save
            end
            @auth_source.destroy
            flash[:notice] = l(:notice_successful_delete)
            redirect_to auth_sources_path
          else
            flash[:error] = l(:error_can_not_delete_auth_source)
            redirect_to :action => 'move_users'
          end
        else
          @auth_source.destroy
          flash[:notice] = l(:notice_successful_delete)
          redirect_to auth_sources_path
        end
      end

      def move_users
        @auth_source  = AuthSource.find(params[:id])
        @auth_sources = AuthSource.where(["#{AuthSource.table_name}.id != ?", @auth_source])
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'AuthSourcesController', 'EasyPatch::AuthSourcesControllerPatch'
