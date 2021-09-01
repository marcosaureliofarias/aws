class EasyContactsToolbarController < ApplicationController

  helper :easy_contacts

  def search
    limit = EasySetting.value('easy_select_limit').to_i
    @easy_contacts = EasyContact.visible.like(params[:easy_query_q]).limit(limit).order("#{EasyContact.table_name}.firstname")
    render(:partial => 'easy_contacts_toolbar/easy_contact', :collection => @easy_contacts.preload(:references_to).inject([]){|mem,var| mem << var; mem += var.references_to; mem }.uniq)
  end

  def show
    respond_to do |format|
      format.js {@easy_contacts = User.current.easy_contacts.preload(:easy_contact_type)}
    end
  end
end
