require 'easy_extensions/spec_helper'

describe EasyKnowledgeStoryQuery do

  let!(:easy_knowledge_stories) { FactoryGirl.create_list(:easy_knowledge_story, 3) }
  let!(:easy_knowledge_story_cf) { FactoryGirl.create(:easy_knowledge_story_cf, :field_format => 'string') }

  it 'has easy knowledge custom field filters' do
    expect(
      EasyKnowledgeStoryQuery.new.available_filters.detect{|n, f| f[:name] == easy_knowledge_story_cf.name}
    ).not_to eq(nil)
  end

end
