require 'easy_extensions/spec_helper'

describe EasyPrintableTemplatesController, logged: :admin do

  describe '#index' do
    it do
      get :index
      expect(response).to be_successful
    end
  end

  describe '#new' do
    it do
      get :new
      expect(response).to be_successful
    end
  end
  
  describe '#preview' do
    render_views
    
    let(:easy_printable_template_page) { FactoryBot.create(:easy_printable_template_page,
        easy_printable_template_id: easy_printable_template.id, page_text: 'Place for NFC chip %easy_short_url_medium_qr%') }
    let(:easy_printable_template) { FactoryBot.create(:easy_printable_template) }
    
    it 'qr code' do
      easy_printable_template_page
      get :preview, params: {id: easy_printable_template.id, tokens: {qr_text: 'aHR0cDovL2xvY2FsaG9zdDozMDAwL2lzc3Vlcy8yMjE2NTU'}}
      expect(response).to be_successful
      expect(response.body).to include('img')
      expect(response.body).to include('base64')
    end

    context 'custom fields' do
      let(:easy_printable_template_page_cf) { FactoryBot.create(:easy_printable_template_page,
        easy_printable_template_id: easy_printable_template.id, page_text: "test: %unknown_cf_1_text% cf value: %task_cf_#{issue_cf.id}% and blank cf %unknown_cf_1% end cf value2: %task_cf_#{issue_cf.id}%") }
      let(:issue) { FactoryBot.create(:issue, tracker: tracker) }
      let(:tracker) { FactoryBot.create(:tracker) }
      let(:issue_cf) { FactoryBot.create(:issue_custom_field, trackers: [tracker], is_for_all: true) }

      it 'replace cf value' do
        issue_cf
        issue.custom_field_values = {issue_cf.id.to_s => 'testing'}
        issue.save
        easy_printable_template_page_cf
        get :preview, params: {id: easy_printable_template.id, entity_type: 'Issue', entity_id: issue.id}
        expect(response).to be_successful
        expect(response.body).to include("test:  cf value: testing and blank cf  end cf value2: testing")
      end
    end
  end

  describe '#generate_docx_from_attachment' do
    def file_fixture(file_name)
      Pathname(File.join(__dir__, '../fixtures/files', file_name))
    end

    let(:project) { FactoryBot.create :project }
    let(:file) { FactoryBot.create(:attachment, file: File.binread(file_fixture('template.docx')), filename: 'template.docx', content_type: '') }
    subject { FactoryBot.create(:easy_printable_template, attachments: [file]) }

    it do
      allow_any_instance_of(Attachment).to receive(:content_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      post :generate_docx_from_attachment, params: { id: subject.id, project_id: project.id }
      expect(response).to have_http_status(:success)
    end
  end

end
