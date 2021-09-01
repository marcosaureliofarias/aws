require 'easy_extensions/spec_helper'

describe EasyKnowledgeStory do

  let(:story) { FactoryBot.create(:easy_knowledge_story) }

  it '#current_version' do
    expect(story.current_version.version).to eq(1)
  end

end