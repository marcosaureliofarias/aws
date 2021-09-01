require_relative '../spec_helper'

describe JournalsController, logged: :admin do

  let(:crm) { FactoryBot.create(:easy_crm_case) }

  context 'diff' do
    def open_diff
      crm.init_journal(User.current)
      crm.description = 'test'
      expect { crm.save }.to change(Journal, :count).by(1)
      journal = crm.journals.first
      get :diff, params: { id: journal.id, detail_id: journal.details.first.id }
    end

    it 'regular', logged: true do
      open_diff
      expect(response).to have_http_status(403)
    end

    it 'admin' do
      open_diff
      expect(response).to have_http_status(200)
    end
  end
end
