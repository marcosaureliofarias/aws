class EasyContactGroupProjectQuery < EasyContactGroupQuery

  def entity_scope
    super.where(:easy_contact_groups => {:entity_type => 'Project'})
  end

end