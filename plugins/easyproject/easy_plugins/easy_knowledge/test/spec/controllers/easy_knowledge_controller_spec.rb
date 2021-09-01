require 'easy_extensions/spec_helper'
# describe EasyKnowledgeController, logged: :admin do
#
#   describe 'api end points' do
#     render_views
#     let!(:easy_knowledge_category) { FactoryGirl.create(:easy_knowledge_category, name: 'Testcategory') }
#     let!(:easy_knowledge_story) { FactoryGirl.create(:easy_knowledge_story, name: 'Teststory') }
#     let!(:easy_knowledge_story_with_category) { FactoryGirl.create(:easy_knowledge_story, name: 'Teststory1', easy_knowledge_categories: [easy_knowledge_category]) }
#
#     # it 'initial load' do
#     #   get :show_as_tree
#     #   expect(response).to be_successful
#     #   hash_body = nil
#     #   expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
#     #   expect(hash_body.keys).to eq(["categories", "stories_without_category", "current_user", "standard_lang_files", "urls", "knowledge_lang_files"])
#     #   expect(hash_body[:categories].count).to eq(1)
#     #   expect(hash_body[:categories].first[:name]).to eq('Testcategory')
#     #   expect(hash_body[:stories_without_category].first[:name]).to eq('Teststory')
#     # end
#
#     it 'data' do
#       params = {entities: [{
#         entity: 'EasyKnowledgeCategory',
#         ids: [easy_knowledge_category.id],
#         columns: ['name', 'author_id', 'created_on'],
#         references: [{
#                        entity: 'EasyKnowledgeStory',
#                        columns: ['name', 'author_id', 'updated_on', 'description']
#                      },
#                      {
#                        entity: 'User',
#                        sources: ['author_id'],
#                        columns: ['name']
#                      }]
#       }]}
#       post :data, params.merge(format: :json)
#       expect(response).to be_successful
#       hash_body = nil
#       expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
#       expect(hash_body.keys).to eq(["EasyKnowledgeCategory", "EasyKnowledgeStory", "User"])
#       expect(hash_body[:EasyKnowledgeCategory].count).to eq(1)
#       expect(hash_body[:EasyKnowledgeStory].count).to eq(1)
#       expect(hash_body[:User].count).to eq(2)
#     end
#   end
#
# end
describe EasyKnowledgeController, logged: :admin do
  context '#search' do
    let!(:easy_knowledge_story1) { FactoryBot.create(:easy_knowledge_story, name: 'Process', description: 'Summary article', tag_list: ['test', 'easy']) }
    let!(:easy_knowledge_story2) { FactoryBot.create(:easy_knowledge_story, name: 'Auto control', tag_list: ['test', 'story', 'knowledge']) }

    it 'matched by all tags, order count' do
      get :search, params: {easy_query_q: 'knowledge test'}
      expect(assigns[:easy_knowledge_stories]).to contain_exactly(easy_knowledge_story2, easy_knowledge_story1)
    end

    it 'matched by name' do
      get :search, params: {easy_query_q: 'control'}
      expect(assigns[:easy_knowledge_stories]).to contain_exactly(easy_knowledge_story2)
    end

    it 'matched by description' do
      get :search, params: {easy_query_q: 'summary'}
      expect(assigns[:easy_knowledge_stories]).to contain_exactly(easy_knowledge_story1)
    end
  end
end
