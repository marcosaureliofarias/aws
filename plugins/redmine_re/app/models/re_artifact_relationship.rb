class ReArtifactRelationship < ActiveRecord::Base
  acts_as_positioned

   SYSTEM_RELATION_TYPES = {
     :pch => "parentchild",
#     :pac => "primary_actor",
#     :ac =>  "actors",
#     :dia => "diagram"
   }

  INITIAL_COLORS= {
    :parentchild   => "#0000ff",
    :dependency    => "#00ff00",
    :conflict      => "#ff0000",
    :rationale     => "#993300",
    :refinement    => "#33cccc",
    :part_of       => "#ffcc00",
    :primary_actor => "#999900",
    :actors        => "#339966",
    :diagram       => "#A127F2"
  }

  # The relationship has ReArtifactProperties as source and sink
  belongs_to :source, :class_name => "ReArtifactProperties"
  belongs_to :sink,   :class_name => "ReArtifactProperties"

  validates :source_id, :uniqueness => { :scope => [:sink_id, :relation_type],
    :message => :re_the_specified_relation_already_exists,
    :case_sensitive => true }

  validates :sink_id, :uniqueness => { :scope => :relation_type,
    :message => :re_only_one_parent_allowed,
    :case_sensitive => true }, :if => Proc.new { |rel| rel.relation_type == "parentchild" }

  validates :relation_type, :presence => true
  validates :sink_id, :presence => true, :unless => Proc.new { |rel| rel.relation_type == "parentchild" }
  validates :sink, :presence => true, :unless => Proc.new { |rel| rel.relation_type == "parentchild" || rel.relation_type == "diagram" }
  validates :source_id, :presence => true
  validate :check_relation_types

  scope :of_project, lambda { |project|
    joins(:source, :sink)
      .where('re_artifact_properties.id = source_id AND sinks_re_artifact_relationships.id = sink_id')
      .where('re_artifact_properties.project_id = ? AND sinks_re_artifact_relationships.project_id = ?', project.id, project.id)
  }

  scope :find_all_relations_for_artifact_id, ->(artifact_id) { where('source_id = ? OR sink_id = ?', artifact_id, artifact_id).distinct }

  def position_scope
    # define a seperate list for each source id and relation type
    self.class.where(source_id: source_id, relation_type: relation_type)
  end

  def position_scope_was
    method = '_was' #method = destroyed? ? '_was' : '_before_last_save'
    source_id_prev = send('source_id' + method)
    relation_type_prev = send('relation_type' + method)
    self.class.where(source_id: source_id_prev, relation_type: relation_type_prev)
  end

  def check_relation_types
    # TODO: :inclusion => { :in => ReRelationtype::gather_all_relation_types.values }
    unless ::ReRelationtype.all.detect{|type| type.relation_type == self.relation_type}
      errors.add(:relation_type, 'Undefined relation type')
    end
  end

end
