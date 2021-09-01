module EasyKnowledge
  module NotifiablePatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do

        class << self

          alias_method_chain :all, :easy_knowledge

        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def all_with_easy_knowledge
        notifications = all_without_easy_knowledge
        notifications << Redmine::Notifiable.new('easy_knowledge_story_added')
        notifications << Redmine::Notifiable.new('easy_knowledge_story_updated')
        notifications
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Notifiable', 'EasyKnowledge::NotifiablePatch'
