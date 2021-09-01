require 'easy_extensions/spec_helper'

describe 'easy_crm_cases/_view_easy_crm_cases_show_journals_top', logged: :admin, skip: !Redmine::Plugin.installed?(:easy_crm) do
  let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case) }

  it 'money overview' do
    render partial: 'easy_crm_cases/view_easy_crm_cases_show_journals_top', locals: {easy_crm_case: easy_crm_case, project: easy_crm_case.project}
  end
end
