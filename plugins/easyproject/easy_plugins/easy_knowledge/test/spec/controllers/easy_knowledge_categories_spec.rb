# require 'easy_extensions/spec_helper'
#
# describe EasyKnowledgeCategoriesController do
#
#   let(:easy_knowledge_category) { FactoryGirl.create(:easy_knowledge_category) }
#   render_views
#
#   context 'admin', logged: :admin do
#     it 'create' do
#       expect{
#         post :create, easy_knowledge_category: {name: 'Update good', description: 'Ema mele mamu'}, format: :json
#       }.to change(EasyKnowledgeCategory, :count).by(1)
#       expect(response).to be_successful
#     end
#
#   end
# end
