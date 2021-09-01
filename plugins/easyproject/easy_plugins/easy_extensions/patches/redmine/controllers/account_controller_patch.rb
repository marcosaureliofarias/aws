module EasyPatch
  module AccountControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        helper :attachments
        include AttachmentsHelper

        accept_api_auth :autologin

        before_action :set_self_registered_on_user, only: :register

        alias_method_chain :successful_authentication, :easy_extensions
        alias_method_chain :login, :easy_extensions
        alias_method_chain :logout, :easy_extensions
        alias_method_chain :lost_password, :easy_extensions

        def autologin
          if user = User.find_by_api_key(api_key_from_request)
            if user.respond_to?(:easy_show_invitation) && user.easy_show_invitation? && (access_token = params.delete(:access_token)).present?
              uri       = URI.parse(OmniAuth::Strategies::SsoEasysoftwareCom.default_options['client_options'].try(:[], 'site'))
              uri.path  = '/auth/sso/user.json'
              uri.query = 'oauth_token=' + access_token

              begin
                json = JSON.load(open(uri))
                if json && (info = json['info'])
                  user.update_columns({
                                          # must_change_passwd: false,
                                          sso_provider:    json['provider'],
                                          sso_uuid:        json['id'],
                                          firstname:       info['first_name'],
                                          lastname:        info['last_name'] || info['first_name'],
                                          easy_avatar_url: info['image']
                                      })

                  user.easy_avatar.destroy if info['image'].present? && user.easy_avatar
                end
              rescue OpenURI::HTTPError => e
                #
              end
            end

            successful_authentication(user)
          else
            redirect_to signin_path(back_url: params[:back_url])
          end
        end

        def quotes
          quote_engine = EasyExtensions.easy_quotes_engine_instance
          @quote       = quote_engine.get_quote
          call_hook(:controller_account_action_quotes_before_render, { :quote => @quote })

          respond_to do |format|
            format.json { render(:json => @quote.to_json) }
            format.xml { render(:xml => @quote.to_xml) }
            format.text { render(:plain => @quote.to_s) }
          end
        end

        def reset_easy_digest_token
          password = params[:password]

          if User.current.check_password?(password)
            User.current.send(:update_easy_digest_token, password, true)
            flash[:notice] = l(:notice_easy_digest_token_updated)
          else
            flash[:error] = l(:notice_account_wrong_password)
          end

          redirect_back_or_default(home_url)
        end

        def my_account_path
          if User.current.allowed_to_globally?(:edit_profile)
            super
          else
            profile_user_path(User.current)
          end
        end

        def sso_autologin
          user = EasyExtensions::Sso.get_sso_user(request)

          if user && user.new_record?
            user.save
          end

          if user && !user.new_record? && user.active?
            successful_authentication(user)
          else
            if user && !user.valid?
              flash[:error] = user.errors.full_messages.join('<br>').html_safe
            else
              flash[:error] = 'Cannot login through single sign on.'
            end

            redirect_to signin_path(back_url: params[:back_url])
          end
        end

        def sso_variables
          unless EasyExtensions::Sso.enabled?
            redirect_to home_path
            return
          end
        end

        protected

        def successful_authentication_redirect_url(user)
          nil # You should override to custom redirect after successful authentication
        end

        private

        def set_self_registered_on_user
          params[:user].merge!({ :self_registered => true }) if !request.get? && params[:user]
        end

        def update_sso_columns(user)
          if sso = session.delete(:sso)
            columns = {sso_provider: sso[:sso_provider], sso_uuid: sso[:sso_uuid]}
            columns[:easy_avatar_url] = sso[:easy_avatar_url] unless sso[:easy_avatar_url].to_s.length > 255
            user.update_columns(**columns)

            if !sso[:email].blank?
              user.email_addresses.create(address: sso[:email], notify: false) if !user.email_addresses.where(address: sso[:email]).exists?
            end
          end
        end

      end
    end

    module InstanceMethods

      def successful_authentication_with_easy_extensions(user)
        update_sso_columns(user)

        logger.info "Successful authentication for '#{user.login}' from #{request.remote_ip} at #{Time.now.utc}"
        # Valid user
        self.logged_user = user
        # generate a key and set cookie if autologin
        if params[:autologin] && Setting.autologin?
          set_autologin_cookie(user)
        end
        call_hook(:controller_account_success_authentication_after, { :user => user })

        successful_authentication_redirect_url(user) || redirect_back_or_default(my_page_path)
      end

      def login_with_easy_extensions
        if request.post?
          authenticate_user
        else
          if User.current.logged?
            successful_authentication_redirect_url(User.current) || redirect_back_or_default(home_url, :referer => true)
          end
        end
      rescue AuthSourceException => e
        logger.error "An error occurred when authenticating #{params[:username]}: #{e.message}"
        render_error :message => e.message
      end

      def logout_with_easy_extensions
        if User.current.anonymous?
          redirect_to home_url
        elsif request.post?
          logout_user
          render template: 'account/bye'
        end
      end

      def lost_password_with_easy_extensions
        (redirect_to(home_url); return) unless Setting.lost_password?
        if prt = (params[:token] || session[:password_recovery_token])
          @token = Token.find_token("recovery", prt.to_s)
          if @token.nil?
            redirect_to home_url
            return
          elsif @token.expired?
            # remove expired token from session and let user try again
            session[:password_recovery_token] = nil
            flash[:error] = l(:error_token_expired)
            redirect_to lost_password_url
            return
          end

          # redirect to remove the token query parameter from the URL and add it to the session
          if request.query_parameters[:token].present?
            session[:password_recovery_token] = @token.value
            redirect_to lost_password_url
            return
          end

          @user = @token.user
          unless @user && @user.active?
            redirect_to home_url
            return
          end
          if request.post?
            if @user.must_change_passwd? && @user.check_password?(params[:new_password])
              flash.now[:error] = l(:notice_new_password_must_be_different)
            else
              @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
              @user.must_change_passwd = false
              if @user.save
                @token.destroy
                Mailer.deliver_password_updated(@user, User.current)
                flash[:notice] = l(:notice_account_password_updated)
                redirect_to signin_path
                return
              end
            end
          end
          render template: "account/password_recovery"
        else
          if request.post?
            email = params[:mail].to_s.strip
            user = User.find_by_mail(email)
            # user not found
            unless user
              flash[:notice] = l(:notice_account_lost_email_sent_unified)
              redirect_to signin_path
              return
            end
            unless user.active?
              handle_inactive_user(user, lost_password_path)
              return
            end
            # user cannot change its password
            unless user.change_password_allowed?
              flash.now[:error] = l(:notice_can_t_change_password)
              return
            end
            # create a new token for password recovery
            token = Token.new(user: user, action: "recovery")
            if token.save
              # Don't use the param to send the email
              recipent = user.mails.detect { |e| email.casecmp(e) == 0 } || user.mail
              Mailer.deliver_lost_password(user, token, recipent)
              flash[:notice] = l(:notice_account_lost_email_sent_unified)
              redirect_to signin_path
            end
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'AccountController', 'EasyPatch::AccountControllerPatch'
