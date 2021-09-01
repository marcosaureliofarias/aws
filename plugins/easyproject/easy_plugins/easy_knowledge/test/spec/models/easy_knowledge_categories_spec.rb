require 'easy_extensions/spec_helper'

feature 'easy knowledge categories', logged: :admin do
  let(:project) { FactoryGirl.create(:project, :enabled_module_names => ['easy_knowledge']) }
  let(:easy_knowledge_category) { FactoryGirl.create(:easy_knowledge_category) }
  let!(:easy_knowledge_category_l1) { FactoryGirl.create(:easy_knowledge_category) }
  let!(:easy_knowledge_category_l2) { FactoryGirl.create(:easy_knowledge_category, :parent => easy_knowledge_category_l1) }
  let!(:easy_knowledge_category_l3) { FactoryGirl.create(:easy_knowledge_category, :parent => easy_knowledge_category_l2) }

  context 'nested set' do
    it 'should create valid tree' do
      easy_knowledge_category_l1.reload; easy_knowledge_category_l2.reload; easy_knowledge_category_l3.reload
      expect(easy_knowledge_category_l1.children.to_a).to eq([easy_knowledge_category_l2])
      expect(easy_knowledge_category_l2.children.to_a).to eq([easy_knowledge_category_l3])
      expect(easy_knowledge_category_l1.self_and_descendants.to_a).to eq([easy_knowledge_category_l1, easy_knowledge_category_l2, easy_knowledge_category_l3])
      expect(easy_knowledge_category_l3.root).to eq(easy_knowledge_category_l1)
      expect(easy_knowledge_category_l2.root).to eq(easy_knowledge_category_l1)
    end

    it 'should destroy l1-l3' do
      expect{easy_knowledge_category_l1.destroy}.to change(EasyKnowledgeCategory, :count).by(-3)
    end

    it 'should destroy l1' do
      easy_knowledge_category
      expect{easy_knowledge_category.destroy}.to change(EasyKnowledgeCategory, :count).by(-1)
    end

    it 'should destroy l3' do
      expect{easy_knowledge_category_l3.destroy}.to change(EasyKnowledgeCategory, :count).by(-1)
    end

    it 'should destroy l1-l3 on project' do
      [easy_knowledge_category_l1, easy_knowledge_category_l2, easy_knowledge_category_l3].each { |c| c.entity = project; c.save; c.reload }
      project.reload
      expect{project.destroy}.to change(EasyKnowledgeCategory, :count).by(-3)
    end
  end
end
