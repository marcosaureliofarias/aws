require 'easy_extensions/spec_helper'

describe EasyContactTypesController, type: :request, logged: :admin do

  let(:easy_contact_type_xml_params) do
    {
      easy_contact_type: {
        type_name: 'Type name',
        is_default: 0,
        core_fields: ['firstname', 'lastname']
      },
      format: :xml }
  end

  subject { FactoryBot.create(:easy_contact_type, type_name: 'Personal type', position: 1, internal_name: 'personal') }

  context 'api' do

    it '#index' do
      easy_contact_type = FactoryBot.create(:easy_contact_type, position: 2)
      subject
      get easy_contact_types_path, params: { format: :xml }
      expect(response.body).to include("<id>#{subject.id}")
      expect(response.body).to include("<type_name>#{subject.type_name}")
      expect(response.body).to include('<required_lastname>true')
      expect(assigns['types']).to eq([subject, easy_contact_type])
    end

    it '#show' do
      get easy_contact_type_path(subject), params: { format: :xml }
      expect(response).to have_http_status(200)
      expect(response.body).to include("<type_name>#{subject.type_name}")
    end

    it '#create' do
      post easy_contact_types_path, params: easy_contact_type_xml_params
      expect(response).to render_template(:show)
      expect(response.content_type).to eq('application/xml')
    end

    it '#update' do
      put easy_contact_type_path(subject), params: easy_contact_type_xml_params
      expect(response).to have_http_status(204)
      expect(subject.reload.type_name).to eq('Type name')
    end

    describe '#destroy' do

      let(:easy_contact) { FactoryBot.create(:easy_contact, type: subject) }

      it 'with related contacts' do
        easy_contact
        delete easy_contact_type_path(subject), params: { format: :xml }
        expect(response).to have_http_status(422)
      end

      it 'without related contact' do
        delete easy_contact_type_path(subject), params: { format: :xml }
        expect(response).to have_http_status(204)
      end

    end
  end
end