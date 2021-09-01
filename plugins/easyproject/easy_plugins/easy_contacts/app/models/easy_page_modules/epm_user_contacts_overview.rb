class EpmUserContactsOverview < EpmProjectContactsOverview

  def category_name
    @category_name ||= 'contacts'
  end

  def get_show_data(settings, user, page_context = {})
    @user = user
    super(settings, user, page_context)
  end

  def self.add_query_scope(query, user=nil)
    user ||= @user
    assigned_contacts_ids = EasyContactEntityAssignment.where(:entity_type => 'Principal', :entity_id => user.id).pluck(:easy_contact_id)
    query.add_additional_scope(:id => assigned_contacts_ids)
    query
  end

end
