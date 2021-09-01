Rys::Patcher.add('EasyAutoCompletesController') do

  apply_if_plugins :easy_extensions

  included do

    def easy_oauth2_client_applications
      @entities = EasyOauth2ClientApplication.like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i).to_a
      @name_column = :name

      respond_to do |format|
        format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: { additional_select_options: false } }
      end
    end

    def easy_oauth2_server_applications
      @entities = EasyOauth2ServerApplication.like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i).to_a
      @name_column = :name

      respond_to do |format|
        format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: { additional_select_options: false } }
      end
    end

  end

end
