class EasyMailCampaignEasyContact < EasyMailCampaign

  entity_class EasyContact
  easy_query_class EasyContactQuery
  mail_to_field_proc Proc.new{|easy_contact| easy_contact.cf_email_value}

end if Redmine::Plugin.installed?(:easy_mail_campaigns)
