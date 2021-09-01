EasySetting.map do

  key :attachment_description do
    from_params { |raw_value|
      @desc_required = (raw_value == 'required')

      if raw_value == 'required' || raw_value == '1'
        true
      else
        false
      end
    }

    after_save {
      if !@desc_required.nil?
        esa       = EasySetting.find_or_initialize_by(name: 'attachment_description_required', project_id: nil)
        esa.value = @desc_required
        esa.save
      end
    }
  end

  # keys :internal_user_limit, :external_user_limit, :is_demo, disabled_from_params: true

end
