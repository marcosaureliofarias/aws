class EasyRakeTaskEasyCrmReceiveMail < EasyRakeTaskReceiveMail

  validates :project_id, :presence => true

  def create_default_options_from_settings(s)
    options = super(s)

    options[:mail_handler_klass] = 'EasyCrmMailHandler'

    options
  end

  def category_caption_key
    :label_easy_crm
  end

  def registered_in_plugin
    :easy_crm
  end

end
