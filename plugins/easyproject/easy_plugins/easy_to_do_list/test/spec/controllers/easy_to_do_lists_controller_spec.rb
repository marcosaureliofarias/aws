require 'easy_extensions/spec_helper'

describe EasyToDoListsController, logged: :admin do
  render_views

  let(:easy_to_do_list) { FactoryBot.create(:easy_to_do_list, user: User.current) }

  describe '#index' do
    context 'API' do
      it 'render' do
        easy_to_do_list
        get :index, params: { format: 'json' }
        expect(response).to be_successful
        expect(json[:easy_to_do_lists].count).to eq(1)
      end
    end
  end

  describe '#show' do
    context 'API' do
      it 'render' do
        get :show, params: { format: 'json', id: easy_to_do_list.id }
        expect(response).to be_successful
        expect(json).to have_key(:easy_to_do_list)
      end
    end
  end
end