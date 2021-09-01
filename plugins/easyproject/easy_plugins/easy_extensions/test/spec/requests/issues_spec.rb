require 'easy_extensions/spec_helper'

describe 'issues', type: :request do
  describe 'GET /issues/:id.:api - description attribute' do
    include_context 'logged as admin'
    let(:issue) { FactoryBot.create(:issue, description: 'https://www.easysoftware.com/') }

    context 'with textilizable true' do
      it 'renders XML with escaped html attributes ' do
        get issue_path(issue, format: :xml, textilizable: true)
        expect(response.body).to include('&lt;/a&gt;') # </a>
        expect(response.body).not_to include('</a>')
      end

      it 'renders valid JSON response' do
        get issue_path(issue, format: :json, textilizable: true)
        expect(response.body).to include('\u003c/a\\u003e') # </a>
        expect(response.body).not_to include('</a>')
      end
    end
  end
end
