class EasyRakeTaskReceiveIssueMail < EasyRakeTaskReceiveMail

  def create_default_options_from_settings(s)
    options = super(s)

    options[:issue] = {}
    %w(project status tracker category priority).each { |a| s[:issue][a.to_sym] = s[a] if s[a] }

    if s['allow_override']
      options[:allow_override] = s['allow_override']
    else
      options[:allow_override] = 'priority'
    end

    options[:mail_handler_klass] = 'EasyIssueMailHandler'

    options
  end

end
