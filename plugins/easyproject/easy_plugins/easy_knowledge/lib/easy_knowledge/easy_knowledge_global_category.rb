module EasyKnowledge
  class EasyKnowledgeGlobalCategory
    attr_reader :easy_knowledge_categories
    def initialize
      @easy_knowledge_categories = EasyKnowledgeCategory.global
    end

    def self.to_s
      'Global'
    end
  end
end
