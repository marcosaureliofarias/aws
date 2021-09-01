module EasyPatch
  module UsersControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        before_action :require_admin, :except => [:show, :save_button_settings, :generate_rss_key, :generate_api_key, :profile, :render_tabs]
        before_action :generate_key, :only => [:generate_rss_key, :generate_api_key]

        skip_before_action :find_user, :only => [:edit, :update] # destroy
        before_action -> { find_user(false) }, :only => [:show, :edit, :update, :destroy_membership, :profile, :render_tabs, :anonymize] #:edit_membership,
        before_action :find_users, :only => [:bulk_destroy]
        before_action -> { find_users(false) }, :only => [:bulk_edit, :bulk_update, :bulk_anonymize]

        layout proc { |_| params[:tab] == 'my_page' ? 'base' : 'admin' }
        before_render :set_default_easy_user_type, :only => [:new]

        helper :easy_bulk_edit
        helper :api_principals

        alias_method_chain :create, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        # alias_method_chain :edit_membership, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :show, :easy_extensions
        alias_method_chain :update, :easy_extensions

        def generate_rss_key
        end

        def generate_api_key
        end

        def save_button_settings
          unless params[:uniq_id].blank? || params[:open].blank?
            user = if params[:user].blank?
                     User.current
                   else
                     User.find(params[:user])
                   end
            # settings & preferences
            preferences = user.pref
            pref        = preferences.others.to_h
            if pref["plus_button_status"].nil?
              pref["plus_button_status"] = { params[:uniq_id] => params[:open].to_boolean }
            else
              pref["plus_button_status"][params[:uniq_id]] = params[:open].to_boolean
            end
            # update
            preferences.others = pref
            preferences.save
          end

          head :ok
        end

        def find_by_user
          scope = User.with_easy_avatar.non_system_flag.sorted.preload(:email_address)
          scope = scope.like(params[:q]) unless params[:q].blank?

          @user_count = scope.count
          @user_pages = Redmine::Pagination::Paginator.new @user_count, per_page_option, params['page']
          @users      = scope.offset(@user_pages.offset).limit(@user_pages.per_page).to_a

          respond_to do |format|
            format.html { render :partial => 'find_by_user_list', :locals => { :users => @users } }
            format.js
          end
        end

        def profile
          respond_to do |format|
            format.js
            format.html {
              unless request.xhr?
                redirect_to user_path(@user)
                return
              end
            }
            format.api { render action: :show }
          end
        end

        def render_tabs
          case params[:tab]
          when 'others'
            render :partial => 'users/tabs/others'
          when 'user_activities'
            events         = Redmine::Activity::Fetcher.new(User.current, author: @user).easy_events(nil, nil, limit: 10)
            @events_by_day = events.group_by { |event| User.current.time_to_date(event.event_datetime) }
            render :partial => 'users/tabs/user_activities'
          when 'user_projects'
            @memberships = users_project_scope.to_a
            render :partial => 'users/tabs/user_projects'
          when 'attendance'
            @attendances = @user.easy_attendances.visible.where("#{EasyAttendance.table_name}.arrival > ?", Date.today).order(:arrival)
            render :partial => 'users/tabs/attendance'
          when 'user_changes_history'
            load_journals
            render partial: 'users/tabs/user_changes_history'
          else
            render_404
          end
        end

        def user_field_mappings
        end

        def user_field_mappings_save
          redirect_back_or_default user_field_mappings_path
        end

        def bulk_edit
          @user = User.new

          @user_mail_notifications = @users.map(&:valid_notification_options).reduce(:&).uniq
          @projects                = @users.map(&:projects).reduce(:&).uniq

          @custom_fields   = @users.map(&:editable_custom_fields).reduce(:&).uniq
          @safe_attributes = @users.map(&:safe_attribute_names).reduce(:&).uniq

          @user_params = params[:user] || {}
          @user_params.each { |k, v| @user_params.delete(k) if v.blank? }
          @user_params[:custom_field_values] ||= {}
          @user_preferences                  ||= {}
          @user.safe_attributes              = @user_params
        end

        def bulk_update
          attributes, preferences, copy_roles_from = parse_params_for_bulk_user_attributes(params)

          unsaved_users = []
          saved_users   = []

          errors = []

          @users.each do |user|
            user.init_journal(User.current)
            user.safe_attributes      = attributes
            user.pref.safe_attributes = preferences if preferences
            user.copy_roles_from(copy_roles_from) if copy_roles_from && user != copy_roles_from

            if user.save
              user.pref.save
              saved_users << user
            else
              unsaved_users << user
              errors << user.errors.full_messages
            end
          end

          respond_to do |format|
            format.js {

              if errors.any?
                @flash_message = errors.join(', ')
              else
                @flash_message = l(:notice_successful_update)
              end
            }
            format.html {

              if errors.any?
                @unsaved_users    = unsaved_users
                @saved_users      = saved_users
                @user_preferences = preferences
                @copy_roles_from  = copy_roles_from
                bulk_edit
                render :action => 'bulk_edit'
              else
                flash[:notice] = l(:notice_successful_update)
                redirect_back_or_default(users_path)
              end

            }
          end
        end

        def bulk_destroy
          @users.destroy_all

          @flash_message = l(:notice_successful_delete)

          respond_to do |format|
            format.js { @flash_message = flash[:error] || flash[:notice] }
            format.html { redirect_back_or_default(users_path) }
          end
        end

        def anonymize
          if @user.anonymize!
            flash[:notice] = l(:notice_successful_anonymized)
          else
            flash[:error] = @user.errors.full_messages.join(', ')
          end

          redirect_back_or_default(user_path(@user))
        end

        def bulk_anonymize
          unsaved_users, saved_users, errors = [], [], []

          @users.each do |user|
            if user.anonymize!
              saved_users << user
            else
              unsaved_users << user
              errors << user.errors.full_messages
            end
          end

          if unsaved_users.empty?
            flash[:notice] = l(:notice_successful_anonymized)
          else
            flash[:error] = errors.join(', ')
          end

          redirect_back_or_default(users_path)
        end

        private

        def generate_key
          @new_key = Token.generate_token_value
        end

        def users_project_scope
          @user.memberships.where(Project.visible_condition(User.current)).where(["#{Project.table_name}.easy_is_easy_template = ?", false]).reorder("#{Project.table_name}.lft")
        end

        def set_default_easy_user_type
          @user.set_default_easy_user_type if @user
        end

        def find_users(logged = true)
          if params[:ids]
            @users = User.where(:id => params[:ids])
            @users = @users.logged if logged
          end
        end

        def parse_params_for_bulk_user_attributes(params)
          attributes      = (params[:user] || {}).reject { |k, v| v.blank? }
          preferences     = nil
          copy_roles_from = nil
          if (copy_roles_from = attributes.delete(:copy_roles_from))
            copy_roles_from = User.find_by(id: copy_roles_from)
          end
          if (preferences = attributes.delete(:pref))
            preferences.reject! { |k, v| v.blank? }
          end

          if attributes[:mail_notification].blank?
            attributes.delete(:notified_project_ids)
          end

          if custom = attributes[:custom_field_values]
            custom.reject! { |k, v| v.blank? }
            custom.each do |k, _|
              if custom[k].is_a?(Array)
                custom[k] << '' if custom[k].delete('__none__')
              else
                custom[k] = '' if custom[k] == '__none__'
              end
            end
          end
          [attributes, preferences, copy_roles_from]
        end

        def vcard
          encoding        = params[:encoding] || 'UTF-8'
          vcard_generator = EasyExtensions::EasyEntityAttributeMappings::VcardMapper.new(@user, EasyExtensions::Export::EasyVcard, :allow_avatar => params[:format] == 'vcf').map_entity
          Redmine::CodesetUtil.safe_from_utf8(vcard_generator.to_vcard, encoding.upcase) if vcard_generator
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        params[:easy_query_q] = params[:name] if params[:name].present?
        retrieve_query(EasyUserQuery)

        sort_init(@query.sort_criteria_init)
        sort_update({ 'id' => "#{User.table_name}.id" }.merge(@query.sortable_columns))

        if params[:group_id].present?
          @query.add_filter('groups', '=', Array(params[:group_id]))
        end

        @users = prepare_easy_query_render

        if request.xhr? && !@entities
          render_404
          return false
        end

        respond_to do |format|
          format.html { render_easy_query_html }
          format.api
          format.csv { send_data(export_to_csv(@users, @query), filename: get_export_filename(:csv, @query)) }
          format.pdf { render_easy_query_pdf }
          format.xlsx { render_easy_query_xlsx }
        end

      end

      def show_with_easy_extensions
        unless @user.visible? || User.current.easy_lesser_admin_for?('users')
          render_404
          return
        end

        # show projects based on current user visibility
        respond_to do |format|
          format.html { render :layout => 'base' }
          format.api
          format.vcf do
            if vcard_export = vcard
              send_data(vcard_export, :filename => "#{@user.name}.vcf")
            else
              flash[:error] = l(:error_easy_entity_attribute_map_invalid)
              return render_404
            end
          end
          format.qr do
            if vcard_export = vcard
              @easy_qr = EasyQr.generate_qr(vcard_export.force_encoding('iso-8859-2'))
              if request.xhr?
                render :template => 'easy_qr/show', :formats => [:js], :locals => { :modal => true }
              else
                render :template => 'easy_qr/show', :formats => [:html], :content_type => 'text/html'
              end
            else
              flash[:error] = l(:error_easy_entity_attribute_map_invalid)
              return render_404
            end
          end
        end
      end

      def create_with_easy_extensions
        @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option, :admin => false)
        if params[:user]
          @user.admin = params[:user][:admin] if params[:user][:admin]
          @user.login = params[:user][:login] if params[:user][:login]
        end
        @user.safe_attributes = params[:user]
        if params[:user]
          @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id
        end
        @user.pref.safe_attributes = params[:pref] if params[:pref]

        call_hook(:controller_users_create_before_save, user: @user)

        if @user.save
          if (easy_page_template_id = (params[:page_template_id].presence || @user.easy_user_type.easy_page_template_id))
            if (page_template = EasyPageTemplate.find_by(id: easy_page_template_id))
              EasyPageZoneModule.create_from_page_template(page_template, @user.id)
            end
          end

          unless params[:copy_roles_from].blank?
            source_user = User.find(params[:copy_roles_from]) rescue nil;
            @user.copy_roles_from(source_user) if source_user
          end

          Mailer.deliver_account_information(@user, @user.password) if params[:send_information]

          # ensure dont need to generate password after email was sent if call save on @user again
          # @see https://git.easy.cz/devel/devel/-/blob/bug-fixing/app/models/user.rb#L129
          @user.password = @user.password_confirmation = nil
          @user.generate_password = false

          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_user_successful_create, :id => view_context.link_to(@user.login, user_path(@user))).html_safe
              if params[:continue]
                attrs = { :generate_password => @user.generate_password }
                redirect_to new_user_path(:user => attrs)
              else
                redirect_to edit_user_path(@user)
              end
            }
            format.api { render :action => 'show', :status => :created, :location => user_url(@user) }
          end
        else
          @auth_sources = AuthSource.all
          # Clear password input
          @user.password = @user.password_confirmation = nil

          respond_to do |format|
            format.html { render :action => 'new' }
            format.api { render_validation_errors(@user) }
          end
        end
      end

      def edit_with_easy_extensions
        @auth_sources = AuthSource.all
        @membership   ||= Member.new
        if params[:tab] == 'my_page'
          if params[:tab_mode] == 'edit'
            render_action_as_easy_page(EasyPage.find_by(page_name: 'my-page'), @user, nil, url_for(:action => 'edit', :id => @user.id, :tab => 'my_page', :t => params[:t]), true)
          elsif params[:tab_mode] == 'template'
          else
            render_action_as_easy_page(EasyPage.find_by(page_name: 'my-page'), @user, nil, url_for(:action => 'edit', :id => @user.id, :tab => 'my_page', :t => params[:t]), false)
          end
        end
      end

      def update_with_easy_extensions
        @user.init_journal(User.current)

        if params[:user]
          if @user.auth_change_allowed?
            if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
              @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
            end
          else
            params[:user].delete(:mail)
          end
        end
        @user.safe_attributes = params[:user]
        # Was the account actived ? (do it before User#save clears the change)
        was_activated              = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
        # TODO: Similar to My#account
        @user.pref.safe_attributes = params[:pref] if params[:pref]

        if @user.save
          @user.pref.save

          unless params[:page_template_id].blank?
            begin
              page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
              EasyPageZoneModule.create_from_page_template(page_template, @user.id)
            rescue ActiveRecord::RecordNotFound
            end
          end

          unless params[:copy_roles_from].blank?
            source_user = User.find_by(:id => params[:copy_roles_from])
            @user.copy_roles_from(source_user) if source_user
          end

          if was_activated
            Mailer.deliver_account_activated(@user)
          elsif @user.active? && params[:send_information] && @user != User.current
            Mailer.deliver_account_information(@user, @user.password)
          end

          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              #redirect_to_referer_or edit_user_path(@user)
              redirect_back_or_default edit_user_path(@user, tab: params[:tab])
            }
            format.api { render_api_ok }
          end
        else
          @auth_sources = AuthSource.all
          @membership   ||= Member.new
          # Clear password input
          @user.password = @user.password_confirmation = nil

          respond_to do |format|
            format.html { render :action => :edit, tab: params[:tab], :locals => { :default_url => { :controller => 'users', :action => 'edit', :id => @user } } }
            format.api { render_validation_errors(@user) }
          end
        end
      end

      # viz RM commit c2e73160daa7782d7a91f2b6a974a936c6f084da
      # def edit_membership_with_easy_extensions
      #   if params[:membership]
      #     project_ids = params[:membership].delete(:project_ids) || []

      #     project_ids.each do |project_id|
      #       next if project_id.blank?
      #       unless Member.where(:user_id => params[:membership][:user_id], :project_id => project_id).exists?
      #         @membership = Member.edit_membership(params[:membership_id], params[:membership], @user)
      #         @membership.project_id = project_id unless project_id.blank?
      #         @membership.save
      #       end
      #     end
      #   end
      #   @membership ||= Member.edit_membership(params[:membership_id], params[:membership], @user)
      #   respond_to do |format|
      #     format.html { redirect_to edit_user_path(@user, :tab => 'memberships') }
      #     format.js
      #   end
      # end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:users)
      end

      def load_journals
        @journals = @user.journals.includes(:journalized, :user, :details).reorder("#{Journal.table_name}.id ASC").to_a
        @journals.each_with_index { |j, i| j.indice = i + 1 }
        @journals.reverse! if User.current.wants_comments_in_reverse_order?
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'UsersController', 'EasyPatch::UsersControllerPatch'
