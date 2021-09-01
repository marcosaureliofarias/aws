module EasyPatch
  module MyControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        include EasyControllersConcerns::EasyPageJournals
        const_set(:JOURNALIZED_ACTIONS, %w(save_my_page_module_view))

        menu_item :my_page

        skip_before_action :require_login
        before_action :prepare_values_for_my_page_new_issue, :only => [:update_my_page_new_issue_attributes, :new_my_page_create_issue, :update_my_page_new_issue_dependent_fields]
        before_action :authorize_entity_create_new, :only => [:new_my_page_create_issue]
        before_action :check_if_login_required, :except => [:toggle_mobile_view]
        before_action :authorize_global, :only => [:page_layout]
        before_action :authorize_or_redirect, :only => [:account, :change_avatar]
        before_action :find_easy_page_module, :find_optional_project_by_project_id, :only => [:update_my_page_module_view, :save_my_page_module_view, :new_my_page_create_issue]

        alias_method_chain :index, :easy_extensions
        alias_method_chain :page, :easy_extensions
        alias_method_chain :account, :easy_extensions

        accept_api_auth_actions << :page

        # Create issue from page module
        def update_my_page_new_issue_dependent_fields
        end

        def update_my_page_new_issue_attributes
        end

        def change_avatar
          respond_to do |format|
            format.js
          end
        end

        def new_my_page_create_issue
          @project      = nil
          @issue.author = User.current

          respond_to do |format|
            @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
            if @issue.save
              flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("#{@issue.to_s}", issue_path(@issue), :title => @issue.subject)).html_safe

              format.html {
                render_attachment_warning_if_needed(@issue)
                redirect_back_or_default :controller => 'my', :action => 'page'
              }
              format.js {
                render_attachment_warning_if_needed(@issue)
                render :js => "window.location.replace('#{back_url || my_page_path}')"
              }
            else
              format.html {
                render_action_as_easy_page(EasyPage.find_by(page_name: 'my-page'), User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), false, { :issue => @issue })
              }
              format.js {
                @module_partial, @module_locals = prepare_render_for_single_easy_page_module(@epzm, nil, nil, nil, nil, nil, nil, false, { project: @project, :issue => @issue, :back_url => back_url })
              }
            end
          end
        end

        # before filter find_easy_page_module
        def update_my_page_module_view
          @epzm.from_params(params[:block_name] ? params[params[:block_name]] : params)
          @epzm.after_load

          edit                   = false
          edit                   = params[:edit] if params.key?(:edit)
          edit                   = params[:inline_edit] if params.key?(:inline_edit)
          edit                   = params[:modal_edit] if params.key?(:modal_edit)

          @epzm.do_not_translate = false if edit

          with_container = !params[:inline_edit].blank? || !params[:modal_edit].blank? || !params[:with_container].blank?
          with_container &&= params[:with_container] != false && params[:with_container] != 'false' if params[:with_container]

          respond_to do |format|
            format.html {
              render_single_easy_page_module(@epzm, nil, nil, nil, nil, nil, edit, with_container, { project: @project, sort: params[:sort] })
            }
            format.js {
              @module_partial, @module_locals = prepare_render_for_single_easy_page_module(@epzm, nil, nil, nil, nil, nil, nil, with_container, { project: @project, sort: params[:sort] })
            }
          end
        end

        def page_layout
          @user = User.current
          render_action_as_easy_page(EasyPage.find_by(page_name: 'my-page'), User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), true)
        end

        # before filter find_easy_page_module
        def save_my_page_module_view
          @page = @epzm.page_definition
          @epzm.from_params(params[@epzm.module_name])
          @epzm.before_save
          @epzm.save

          respond_to do |format|
            format.html {
              redirect_back_or_default home_path(t: params[:t])
            }
            format.api {
              render_api_ok
            }
          end
        end

        def toggle_mobile_view
          session[:mobile_view] = !session[:mobile_view]

          redirect_back_or_default home_url
        end

        def mobile_page_layout
          @user = User.current
          render_action_as_easy_page(EasyPage.find_by(page_name: 'my-mobile-page'), User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), true)
        end

        def login_or_logout
          if EasyAttendance.enabled?
            pp 'dochazka zapnuta'

            if ca = User.current.current_attendance
              pp 'existuje dnesni attendance'

              if ca.arrival.to_date == Date.today
                if (Time.now - ca.created_at) >= 300
                  pp 'Jedna se o odchod, zapis cas a odhlasit se'

                  if User.current.spent_time_percentage_for(ca.created_at.to_date) >= 75
                    pp 'Mas dostatek vykazaneho casu, jen se odhlas'

                    redirect_to force_user_logout_path
                  else
                    pp 'Mas malo vykazaneho casu, je treba ho vyplnit a az pak se odhlasit'

                    redirect_to new_easy_time_entry_path(:next => 'logout', :spent_on => ca.created_at.to_date)
                  end
                else
                  pp 'Jedna se o prichod, nedelej nic'

                  redirect_back_or_default home_url
                end
              else
                pp 'dnesni dochazka neexistuje, ale vcera je otevrena'

                redirect_back_or_default home_url
              end
            else
              pp '????????????'

              redirect_back_or_default home_url
            end
          else
            pp 'dochazka vypnuta'

            redirect_back_or_default home_url
          end
        end

        def force_user_logout
          if EasyAttendance.enabled? && User.current.current_attendance
            pp 'Odhlasuju z dochazky'

            EasyAttendance.create_departure(User.current.current_attendance, current_user_ip, :force => true)
          end

          logout_user

          redirect_to home_url
        end

        def force_user_login
        end

        private

        def prepare_values_for_my_page_new_issue
          if params[:block_name].nil?
            redirect_to :controller => 'my', :action => 'page'
          else

            my_params               = params[params[:block_name] + 'issue']
            my_params[:update_form] = request.xhr?
            @user                   = User.find(params[:user_id])
            @project                = Project.find_by(:id => my_params[:project_id])
            @issue                  = Issue.new
            @issue.project          = @project
            if @project
              tracker_id = my_params.delete :tracker_id
              if @project.trackers.exists?(tracker_id)
                @issue.tracker = @project.trackers.find(tracker_id)
              else
                @issue.tracker = @project.trackers.first
              end
            end
            @issue.author          = @user
            @issue.safe_attributes = my_params
            @issue.start_date      ||= Date.today

            #@projects = Project.visible(@user).non_templates
            @issue_priorities = IssuePriority.active
            @assignable_users = @issue.assignable_users
            @allowed_statuses = @issue.new_statuses_allowed_to(@user, true)


            if User.current.allowed_to?(:add_issue_watchers, @issue.project) && @issue.new_record? && my_params['watcher_user_ids']
              @issue.watcher_user_ids  = my_params['watcher_user_ids']
              @issue.watcher_group_ids = my_params['watcher_group_ids']
            end

            @issue_data = { params[:block_name] => @issue }
          end
        end

        def authorize_entity_create_new
          if @project
            authorize
          else
            authorize_global
          end
        end

        def find_easy_page_module
          @epzm = if params[:template] == '1'
                    EasyPageTemplateModule.preload([:page_definition, :module_definition]).find_by(:uuid => params[:uuid])
                  else
                    EasyPageZoneModule.preload([:user, :page_definition, :module_definition]).find_by(:uuid => params[:uuid])
                  end
          render_404 unless @epzm
        end

        def authorize_or_redirect
          redirect_to profile_user_path(User.current) unless User.current.allowed_to_globally?(:edit_profile)
        end

      end

    end

    module InstanceMethods

      def index_with_easy_extensions
        page
      end

      # Edit user's account
      def account_with_easy_extensions
        @user = User.current
        @pref = @user.pref

        if request.put?
          @user.safe_attributes      = params[:user] if params[:user]
          @user.pref.safe_attributes = params[:pref] if params[:pref]
          avatar_image               = params[:user][:easy_avatar]

          if @user.save
            @user.pref.save
            set_language_if_valid @user.language

            respond_to do |format|
              format.html do
                if avatar_image.present?
                  a = EasyAvatar.new(entity: @user, image: avatar_image)
                  a.valid?
                  if a.errors[:image].blank?
                    @user.easy_avatar = a
                    flash[:notice] = l(:notice_account_updated)
                    redirect_to(crop_easy_avatar_path(:entity_id => @user, :entity_type => @user.class.name, :back_url => params[:back_url]))
                  else
                    flash[:error] = a.errors.messages[:image].join('<br>').html_safe
                    render action: :account
                  end
                end
              end
              format.api  { render_api_ok }
            end
          else
            respond_to do |format|
              format.html { render action: :account }
              format.api  { render_validation_errors(@user) }
            end
          end
        end
      end

      def page_with_easy_extensions
        @user      = User.current
        params[:t] ||= back_url.match(/(?<=t=)[\d]{1,2}/).try(:[], 0) if back_url
        respond_to do |format|
          format.html do
            # if in_mobile_view?
            #   render_action_as_easy_page(EasyPage.find_by(page_name: 'my-mobile-page'), User.current, nil, url_for(:controller => 'my', :action => 'page'), false, {page_editable: User.current.allowed_to_globally?(:manage_my_page)})
            # else
            render_action_as_easy_page(EasyPage.find_by(page_name: 'my-page'), User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), false, { page_editable: User.current.allowed_to_globally?(:manage_my_page) })
            # end
          end
          format.json do
            modules = EasyPage.find_by(page_name: 'my-mobile-page').user_modules(User.current, nil, nil, all_tabs: true)

            queries = modules.values.flatten.map { |m| m.get_show_data(User.current)[:query] }.compact

            queries_hash = queries.map do |query|
              {
                  name:              query.name,
                  query_type:        query.type,
                  filters:           query.filters,
                  entity_class_name: (query.entity.respond_to?(:class_name) ? query.entity.class_name : query.entity.name),
                  query_params:      query.to_params,
                  url:               polymorphic_url(query.entity, { format: :json }.merge(query.to_params))
              }
            end

            render json: queries_hash
          end
        end
      end
    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'MyController', 'EasyPatch::MyControllerPatch'
