require 'easy_extensions/spec_helper'

describe EasyButtonsController, logged: :admin do
  let(:easy_button1) { FactoryBot.create(:easy_button) }
  let(:easy_button2) { FactoryBot.create(:easy_button) }

  it 'should not destroy object' do
    ids = [easy_button2.id]
    expect { delete :bulk_destroy, params: {ids: ids} }.to change(EasyButton, :count).by(0)
  end

  it 'should change deleted field to true' do
    delete :bulk_destroy, params: {ids: [easy_button2.id]}
    expect(EasyButton.where(deleted: true).pluck(:id)).to include(easy_button2.id)
    expect(flash[:notice]).to include "(1)"
  end
end
