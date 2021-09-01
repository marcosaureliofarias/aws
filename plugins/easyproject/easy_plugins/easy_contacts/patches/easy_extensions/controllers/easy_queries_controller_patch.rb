module EasyContacts
  module EasyQueriesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :add_additional_statement_to_query, :easy_contact

      end
    end

    module InstanceMethods

      def add_additional_statement_to_query_with_easy_contact(query)
        if query.is_a?(EasyContactQuery) && !params[:block_name].to_s.include?('easy_contact_query')
          if params[:project_id].present?
            project = Project.find(params[:project_id])
            EpmProjectContactsOverview.add_query_scope(query, project)
          else
            EpmUserContactsOverview.add_query_scope(query, User.current)
          end
        else
          add_additional_statement_to_query_without_easy_contact(query)
        end

      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch('EasyQueriesController', 'EasyContacts::EasyQueriesControllerPatch')
