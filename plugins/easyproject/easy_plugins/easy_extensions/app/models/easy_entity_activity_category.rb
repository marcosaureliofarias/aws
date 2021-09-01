class EasyEntityActivityCategory < Enumeration
  acts_as_easy_translate

  has_many :easy_entity_activities

  OptionName = :enumeration_easy_entity_activity_category

  def option_name
    OptionName
  end

  def transfer_relations(to)
    easy_entity_activities.update_all(:category_id => to.id)
  end
end
