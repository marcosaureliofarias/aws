require 'easy_extensions/spec_helper'

describe EasyToDoListItemsController, logged: :admin do
  render_views

  let(:easy_to_do_list) { FactoryBot.create(:easy_to_do_list, user: User.current) }
  let(:easy_to_do_list_item) { FactoryBot.create(:easy_to_do_list_item, easy_to_do_list: easy_to_do_list) }

  describe '#index' do
    context 'API' do
      it 'render' do
        easy_to_do_list_item
        get :index, params: { format: 'json', easy_to_do_list_id: easy_to_do_list.id }
        expect(response).to be_successful
        expect(json[:easy_to_do_list_items].count).to eq(1)
      end
    end
  end

  describe '#show' do
    context 'API' do
      it 'render' do
        get :show, params: { format: 'json', id: easy_to_do_list_item.id }
        expect(response).to be_successful
        expect(json).to have_key(:easy_to_do_list_item)
      end
    end
  end
end