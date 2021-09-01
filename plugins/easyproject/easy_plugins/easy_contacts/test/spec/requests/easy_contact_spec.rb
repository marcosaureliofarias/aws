require 'easy_extensions/spec_helper'
describe EasyContactsController, type: :request, skip: !Redmine::Plugin.installed?(:easy_crm) || !Redmine::Plugin.installed?(:easy_invoicing)  do

  let(:easy_crm_case) { FactoryBot.create(:easy_crm_case) }
  let(:easy_invoice) { FactoryBot.create(:easy_invoice) }
  let(:issue) { FactoryBot.create(:issue) }
  let(:project) { FactoryBot.create(:project) }

  subject { FactoryBot.create(:easy_contact,
                              easy_crm_cases: [easy_crm_case],
                              easy_invoices: [easy_invoice],
                              issues: [issue],
                              projects: [project],
                              users: [User.current])
  }

  describe '#show' do
    context 'with easy contact entity assignments' do
      include_context 'logged as admin'
      it 'should render template' do
        get easy_contact_path(subject)
        expect(response).to have_http_status(200)
        expect(response).to render_template('easy_contacts/show')
      end
    end
  end
end