class ReRelationtype < ActiveRecord::Base
  #validates :id, :presence => true, :numericality => true
  validates :project_id, :presence => true, :numericality => true
  validates :relation_type, :presence => true
  validates :alias_name, :presence => true
  validates :color, :format => { :with => /\A#?(?:[A-F0-9]{3}){1,2}\z/i }
  validates :is_system_relation, :inclusion => { :in => [0, 1] }
  validates :is_directed, :inclusion => { :in => [0, 1] }
  validates :in_use, :inclusion => { :in => [0, 1] }

  def self.relation_types(project_id, is_system_relation=nil, is_used_relation=nil)
    params = { project_id: project_id }
    params[:is_system_relation] = is_system_relation unless  is_system_relation == nil
    params[:in_use] = is_used_relation unless is_used_relation == nil

    ReRelationtype.where(params).map { |relation_type| relation_type.relation_type }
  end

  def self.in_use(relation_type, project_id)
    ReRelationtype.find_by(project_id: project_id, relation_type: relation_type, in_use: 1).present? ? true : false
  end

  def self.get_alias_name(relation_type, project_id)
    relation_type = ReRelationtype.find_by(project_id: project_id, relation_type: relation_type)
    relation_type ? relation_type.alias_name : ''
  end
end
