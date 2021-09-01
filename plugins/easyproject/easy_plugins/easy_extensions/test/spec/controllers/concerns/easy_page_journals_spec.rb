require 'easy_extensions/spec_helper'

RSpec.describe EasyControllersConcerns::EasyPageJournals, type: :controller, logged: :admin do

  controller do
    include EasyControllersConcerns::EasyPageJournals

    def index
      head :ok
    end
  end

  describe '#create_easy_page_journal' do
    let(:easy_page) { FactoryBot.create(:easy_page) }

    it 'creates a journal' do
      controller.instance_variable_set(:@page, easy_page)
      allow(controller).to receive(:journalized_actions).and_return(%w(index))

      expect { get :index }.to change(Journal, :count).by(1)
    end
  end

end
