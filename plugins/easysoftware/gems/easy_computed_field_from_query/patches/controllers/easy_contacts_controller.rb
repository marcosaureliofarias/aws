Rys::Patcher.add('EasyContactsController') do
  apply_if_plugins :easy_extensions, :easy_contacts

  included do
    def recalculate_cf
      find_contact
      return unless @easy_contact

      EasyRakeTaskComputedFromQuery.recalculate_entity(@easy_contact)

      flash[:notice] = l(:notice_successful_update)

      redirect_to easy_contact_path(@easy_contact)
    end
  end

  instance_methods do
  end

  class_methods do
  end
end
