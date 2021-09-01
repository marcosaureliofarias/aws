module EasyCrm
  module MyControllerPatch

    def self.included(base)
      base.class_eval do

        before_action :prepare_easy_crm_case_from_params, only: [:create_crm_case_from_module, :update_my_page_new_easy_crm_case_attributes]
        before_action :authorize_easy_crm, only: [:create_crm_case_from_module]
        before_action :find_easy_crm_page_module, only: [:create_crm_case_from_module]


        # Create crm case from page module
        def update_my_page_new_easy_crm_case_attributes
        end

        def create_crm_case_from_module
          respond_to do |format|
            @easy_crm_case.save_attachments(params[:attachments] || (params[:easy_crm_case] && params[:easy_crm_case][:uploads]))
            if @easy_crm_case.save
              flash[:notice] = l(:notice_easy_crm_case_successful_create, id: view_context.link_to("#{@easy_crm_case.to_s}", easy_crm_case_path(@easy_crm_case), title: @easy_crm_case.name)).html_safe

              format.html {
                render_attachment_warning_if_needed(@easy_crm_case)
                redirect_back_or_default my_page_path
              }
              format.js {
                redirect_path = @send_to_external_mails ? preview_external_email_easy_crm_case_path(@easy_crm_case, back_url: back_url) : back_url || my_page_path
                render_attachment_warning_if_needed(@easy_crm_case)
                render js: "window.location.replace('#{redirect_path}')"
              }
            else
              format.html {
                render_action_as_easy_page(EasyPage.find_by(page_name: 'my-page'), User.current, nil, url_for(controller: 'my', action: 'page', t: params[:t]), false, {easy_crm_case: @easy_crm_case})
              }
              format.js {
                @module_partial, @module_locals = prepare_render_for_single_easy_page_module(@epzm, nil, nil, nil, nil, nil, nil, false, {easy_crm_case: @easy_crm_case, back_url: back_url})
              }
            end
          end
        end

        private

        def prepare_easy_crm_case_from_params
          if params[:block_name].nil?
            redirect_to controller: 'my', action: 'page'
          else
            @easy_crm_case = EasyCrmCase.new
            block_params_key = params[:block_name]+'easy_crm_case'
            my_params = {}
            my_params = params[block_params_key].to_unsafe_hash if params[block_params_key]
            my_params = my_params.merge(params[:easy_crm_case].to_unsafe_hash) if params[:easy_crm_case]
            my_params[:update_form] = request.xhr?
            @easy_crm_case.safe_attributes = my_params
            @easy_crm_case.easy_crm_case_status ||= EasyCrmCaseStatus.default || EasyCrmCaseStatus.first
            @easy_crm_case.currency ||= @easy_crm_case.project.try(:easy_currency_code)
            @easy_crm_case.author ||= User.current
            @project = @easy_crm_case.project

            @send_to_external_mails = my_params[:send_to_external_mails] == '1'
            @block_name = params[:block_name]
            @shown_fields = (params[:shown_fields] || []).map!(&:to_sym)
            @only_selected = params[:only_selected]
            @custom_field_values = my_params[:custom_field_values]
            @shown_custom_field_ids = params[:shown_custom_field_ids] || []
          end
        end

        def authorize_easy_crm
          authorize_entity_create_new
        end

        def find_easy_crm_page_module
          find_easy_page_module
        end

      end
    end

  end
end

EasyExtensions::PatchManager.register_controller_patch 'MyController', 'EasyCrm::MyControllerPatch'
