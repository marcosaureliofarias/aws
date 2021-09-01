module EasyKnowledge
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def ckeditor_easy_knowledge_stories
          column = "#{EasyKnowledgeStory.table_name}.id"
          column = "CAST(#{column} AS TEXT)" if Redmine::Database.postgresql?
          @entities = EasyKnowledgeStory.visible.where(Redmine::Database.like(column, '?'), "#{params[:query]}%").
            limit(EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.json { render json: @entities.map{|e| {id: e.id, name: e.id, subject: e.name}} }
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyKnowledge::EasyAutoCompletesControllerPatch'
