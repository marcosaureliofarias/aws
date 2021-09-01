class EasyProjectPriority < Enumeration
  acts_as_easy_translate

  has_many :projects, foreign_key: 'easy_priority_id'

  OptionName = :enumeration_easy_project_priority

  def option_name
    OptionName
  end

  def objects_count
    projects.count
  end

  def to_s
    name
  end

  def transfer_relations(to)
    projects.update_all(:easy_priority_id => to.id)
  end

end
