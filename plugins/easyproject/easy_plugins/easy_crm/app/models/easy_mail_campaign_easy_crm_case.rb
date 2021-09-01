class EasyMailCampaignEasyCrmCase < EasyMailCampaign

  entity_class EasyCrmCase
  easy_query_class EasyCrmCaseQuery
  mail_to_field_proc Proc.new{|easy_crm_case| easy_crm_case.email}

end if Redmine::Plugin.installed?(:easy_mail_campaigns)
