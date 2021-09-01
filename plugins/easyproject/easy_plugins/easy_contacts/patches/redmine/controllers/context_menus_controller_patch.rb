module EasyContacts
  module ContextMenusControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_contacts
        include EasyContactsHelper
        include ModalSelectorTagsHelper

        def easy_contacts
          @easy_contacts = EasyContact.find(params[:ids])
          @project = Project.find(params[:project_id]) if params[:project_id]
          can_edit = @easy_contacts.detect { |c| !c.editable? }.nil?
          can_delete = @easy_contacts.detect { |c| !c.deletable? }.nil?
          @can = { edit: can_edit, delete: can_delete }
          @easy_contact_ids = @easy_contacts.map(&:id).sort

          render :layout => false
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def easy_contact_groups
          @project = Project.find(params[:project_id]) if params[:project_id]

          render :layout => false
        rescue ActiveRecord::RecordNotFound
          render_404
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch('ContextMenusController', 'EasyContacts::ContextMenusControllerPatch')
