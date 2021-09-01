module EasyContacts
  module EasyAutoCompletesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_contacts_with_parents
          @entities = get_easy_contacts_with_parents(params[:term], EasySetting.value('easy_select_limit').to_i)

          @name_column = :to_s
          respond_to do |format|
            format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: {additional_select_options: false} }
          end
        end

        def easy_contacts_with_children
          @entities = get_easy_contacts_with_children(params[:term], EasySetting.value('easy_select_limit').to_i)

          @name_column = :to_s
          respond_to do |format|
            format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: {additional_select_options: false} }
          end
        end

        def partner_contacts
          @entities = get_partner_contacts(params[:term], EasySetting.value('easy_select_limit').to_i)

          @name_column = :to_s
          respond_to do |format|
            format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: { additional_select_options: false } }
          end
        end

        def root_easy_contacts
          @entities = get_root_easy_contacts(params[:term], EasySetting.value('easy_select_limit').to_i)

          @name_column = :to_s
          respond_to do |format|
            format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api], locals: { additional_select_options: false } }
          end
        end

        def easy_contacts_project_contacts
          @easy_contacts = get_easy_contacts_project_contacts(params[:term], EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.api { render template: 'easy_auto_completes/easy_contacts', formats: [ :api ] }
          end
        end

        def easy_contacts_visible_contacts
          @easy_contacts = get_easy_contacts_visible_contacts(params[:term], EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.api { render template: 'easy_auto_completes/easy_contacts', formats: [ :api ] }
          end
        end

        def easy_contacts_visible_selected_types
          @easy_contacts = get_easy_contacts_visible_selected_types(params[:term], EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.api { render template: 'easy_auto_completes/easy_contacts', formats: [ :api ] }
          end
        end

        # ckeditor
        # easy_contact#123
        def ckeditor_easy_contacts
          column = "#{EasyContact.table_name}.id"
          column = "CAST(#{column} AS TEXT)" if Redmine::Database.postgresql?
          @entities = EasyContact.visible.where(Redmine::Database.like(column, '?'), "#{params[:query]}%").limit(EasySetting.value('easy_select_limit').to_i)

          respond_to do |format|
            format.json { render json: @entities.map{|e| {id: e.id, name: e.id, subject: e.name}} }
          end
        end

        def assignable_principals_easy_contact
          entity   = EasyContact.find_by(id: params[:easy_contact_id])
          entity   ||= EasyContact.new

          assignable_users = User.active.non_system_flag.sorted.like(params['term'])
          assignable_users = if params[:external]
            assignable_users.easy_type_partner
          else
            assignable_users.easy_type_regular
          end

          assignable_principals_base(entity, assignable_users.to_a)
        end

        private

        def get_easy_contacts_project_contacts(term, limit=nil)
          project = Project.find(params[:project_id])
          project.easy_contacts.preload(:easy_contact_type).visible.like(term).limit(limit).order("#{EasyContact.table_name}.firstname")
        end

        def get_easy_contacts_visible_contacts(term, limit=nil)
          if /^\d+$/.match?(term)
            Array(EasyContact.visible.find_by(id: term))
          else
            EasyContact.preload(:easy_contact_type).visible.like(term).limit(limit).order("#{EasyContact.table_name}.firstname")
          end
        end

        def get_easy_contacts_visible_selected_types(term, limit=nil)
          types = EasySetting.value('easy_contacts_autocomplete_types')
          scope = EasyContact.visible.joins(:easy_contact_type).where(easy_contact_type: { internal_name: types })
          if /^\d+$/.match?(term)
            scope.where(id: term)
          else
            scope.like(term).limit(limit).order("#{EasyContact.table_name}.firstname")
          end
        end

        def get_easy_contacts_with_parents(term='', limit=nil)
          get_easy_contacts_visible_contacts(term, limit).where.not(parent_id: nil).to_a
        end

        def get_easy_contacts_with_children(term='', limit=nil)
          get_easy_contacts_visible_contacts(term, limit).where("#{EasyContact.table_name}.rgt - #{EasyContact.table_name}.lft > 1").to_a
        end

        def get_root_easy_contacts(term='', limit=nil)
          get_easy_contacts_visible_contacts(term, limit).where(parent_id: nil).to_a
        end

        def get_partner_contacts(term='', limit=nil)
          if /^\d+$/.match?(term)
            Array(EasyContact.visible.partner.find_by(id: term))
          else
            EasyContact.preload(:easy_contact_type).visible.partner.like(term).limit(limit).order("#{EasyContact.table_name}.firstname")
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyContacts::EasyAutoCompletesControllerPatch'
