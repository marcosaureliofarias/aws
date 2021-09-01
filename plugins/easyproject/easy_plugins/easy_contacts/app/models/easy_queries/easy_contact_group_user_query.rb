class EasyContactGroupUserQuery < EasyContactGroupQuery

  def entity_scope
    super.where(:easy_contact_groups => {:entity_type => 'User'})
  end

end