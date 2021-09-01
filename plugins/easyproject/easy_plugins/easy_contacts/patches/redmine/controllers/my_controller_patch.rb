module EasyContacts
  module MyControllerPatch

    def self.included(base)
      base.class_eval do


        before_action :prepare_easy_contact_from_params, only: [:create_contact_from_module, :update_my_page_new_easy_contact_attributes]
        before_action :authorize_easy_contact, only: [:new_my_page_create_issue, :create_contact_from_module, :create_crm_case_from_module]
        before_action :find_easy_contact_page_module, only: [:create_contact_from_module]

        # Create contact from page module
        def update_my_page_new_easy_contact_attributes
        end

        def create_contact_from_module
          respond_to do |format|
            @easy_contact.save_attachments(params[:attachments] || (params[:easy_contact] && params[:easy_contact][:uploads]))
            if @easy_contact.save
              flash[:notice] = l(:notice_easy_contact_successful_create, id: view_context.link_to("#{@easy_contact.to_s}", easy_contact_path(@easy_contact), title: @easy_contact.name)).html_safe

              format.html {
                render_attachment_warning_if_needed(@easy_contact)
                redirect_back_or_default my_page_path
              }
              format.js {
                render_attachment_warning_if_needed(@easy_contact)
                render js: "window.location.replace('#{back_url || my_page_path}')"
              }
            else
              format.html {
                render_action_as_easy_page(EasyPage.find_by(page_name: 'my-page'), User.current, nil, url_for(controller: 'my', action: 'page', t: params[:t]), false, {easy_contact: @easy_contact})
              }
              format.js {
                @module_partial, @module_locals = prepare_render_for_single_easy_page_module(@epzm, nil, nil, nil, nil, nil, nil, false, {easy_contact: @easy_contact, back_url: back_url})
              }
            end
          end
        end

        private

        def prepare_easy_contact_from_params
          if params[:block_name].nil?
            redirect_to controller: 'my', action: 'page'
          else
            @easy_contact = EasyContact.new
            block_params_key = params[:block_name]+'easy_contact'
            my_params = {}
            my_params = params[block_params_key].to_unsafe_hash if params[block_params_key]
            my_params = my_params.merge(params[:easy_contact].to_unsafe_hash) if params[:easy_contact]
            my_params[:update_form] = request.xhr?
            @user = User.current
            @easy_contact.author = @user
            @easy_contact.easy_contact_type = EasyContactType.default
            reference_ids = params[:easy_contact_references]
            @easy_contact.references_by = EasyContact.where(id: reference_ids) if reference_ids.present?
            @easy_contact.safe_attributes = my_params

            @block_name = params[:block_name]
            @shown_fields = (params[:shown_fields] || []).map(&:to_sym)
            @only_selected = params[:only_selected]
            @custom_field_values = my_params[:custom_field_values] || {}
            @shown_custom_field_ids = params[:shown_custom_field_ids] || []
          end
        end

        def authorize_easy_contact
          authorize_global
        end

        def find_easy_contact_page_module
          find_easy_page_module
        end

      end
    end

  end
end

EasyExtensions::PatchManager.register_controller_patch 'MyController', 'EasyContacts::MyControllerPatch'
