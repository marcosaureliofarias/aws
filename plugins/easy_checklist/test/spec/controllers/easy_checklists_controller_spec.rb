require 'easy_extensions/spec_helper'

describe EasyChecklistsController, :logged => :admin do

  render_views

  it 'create template' do
    post :create, :params => {:entity_type => 'EasyChecklistTemplate',
      :easy_checklist => { :name => 'checklist', :project_ids => [],
      :is_default_for_new_projects => '1',
      :easy_checklist_items_attributes => {:'0' => {:subject => 'item', :_destroy => 'false', :done => 'false'}},
      }}
      expect(assigns(:easy_checklist).valid?).to eq(true)
      expect(EasyChecklistTemplate.count).to eq(1)
      expect(EasyChecklistItem.count).to eq(1)
  end

  context 'api' do
    let(:easy_checklist) { FactoryBot.create(:easy_checklist, easy_checklist_items: [easy_checklist_item]) }
    let(:easy_checklist_item) { FactoryBot.create(:easy_checklist_item) }

    it '#show' do
      get :show, params: { id: easy_checklist, format: :xml }
      expect( response.body ).to include(easy_checklist.name)
    end

    it '#create' do
      expect { post :create, params: {
        easy_checklist: {
          name: 'checklist', easy_checklist_items_attributes: { '0' => { subject: 'item', done: 'false' } }
        },
        format: :xml
      } }.to change(EasyChecklist, :count).by(1).and change(EasyChecklistItem, :count).by(1)
    end

    it '#update' do
      patch :update, params: {
        id: easy_checklist,
        easy_checklist: {
          name: 'renamed_checklist',
          easy_checklist_items_attributes: { '0' => { subject: 'renamed_item', id: easy_checklist_item } }
        }, format: :xml
      }
      expect(assigns[:easy_checklist].name).to eq('renamed_checklist')
      expect(easy_checklist_item.reload.subject).to eq('renamed_item')
    end

    it '#destroy' do
      expect{ delete :destroy, params: { id: easy_checklist, format: :xml } }.to change(EasyChecklist, :count).by(1)
    end

  end

end
