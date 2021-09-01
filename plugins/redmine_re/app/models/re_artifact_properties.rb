class ReArtifactProperties < ActiveRecord::Base
  include ReArtifactPropertiesVersions::Relationships

  acts_as_paranoid

  html_fragment :description, scrub: :strip
  html_fragment :acceptance_criteria, scrub: :strip

  scope :without_projects, -> { where.not(artifact_type: 'Project') }
  scope :of_project, ->(project) { where({ project_id: project.id }) }
  scope :of_projects, ->(projects) { where({ project: projects }) }

  scope :common_issues, ->(issues) {
    artifact_ids = []

    unless issues.nil? || issues.empty?
      get_realizations = ->(issue) { issue.re_realizations.pluck(:re_artifact_properties_id) }
      artifact_ids = get_realizations.call(issues.first)
      issues.each { |issue| artifact_ids &= get_realizations.call(issue) }
    end

    where(id: artifact_ids)
  }

  # TODO: clean unused associations

  has_many :re_ratings, :dependent => :destroy

  has_many :raters, :through => :re_ratings, :source => :users
  has_many :comments, -> { order("created_on asc") }, :as => :commented, :dependent => :destroy
  has_many :re_realizations, :dependent => :destroy
  has_many :issues, -> { distinct }, :through => :re_realizations

  has_many :relationships_as_source,
           -> { order("re_artifact_relationships.position") },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :relationships_as_sink,
           -> { order("re_artifact_relationships.position") },
           :foreign_key => "sink_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :traces_as_source,
           -> { where.not(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:pch] }).order("re_artifact_relationships.position") },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :traces_as_sink,
           -> { where.not(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:pch] }).order("re_artifact_relationships.position") },
           :foreign_key => "sink_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :user_defined_relations,
           -> { where.not(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:pch] }).order("re_artifact_relationships.position") },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_one :parent_relation,
          -> { where(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:pch] }).order("re_artifact_relationships.position") },
          :foreign_key => "sink_id",
          :class_name => "ReArtifactRelationship",
          :dependent => :destroy

  has_many :child_relations,
           -> { where(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:pch] }).order("re_artifact_relationships.position") },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

           #######
  has_many :primary_relations,
           -> { where(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:pac] }).order("re_artifact_relationships.position") },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :actors_relations,
           -> { where(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:ac] }).order("re_artifact_relationships.position") },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy


  has_many :diagram_relations,
            -> { where(re_artifact_relationships: { relation_type: ReArtifactRelationship::SYSTEM_RELATION_TYPES[:dia] }) },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :related_diagrams, :through => :diagram_relations, :source => "sink" # :class_name => "ConcreteDiagram",

  has_many :dependency_relations,
           -> { where(re_artifact_relationships: { relation_type: 'dependency' }) },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :conflict_relations,
           -> { where(re_artifact_relationships: { relation_type: 'conflict' }) },
           :foreign_key => "source_id",
           :class_name => "ReArtifactRelationship",
           :dependent => :destroy

  has_many :sinks, -> { order("re_artifact_relationships.position") },  :through => :traces_as_source
  has_many :children, -> { order("re_artifact_relationships.position") }, :through => :child_relations, :source => "sink"
  ###
  has_many :primary, -> { order("re_artifact_relationships.position") }, :through => :primary_relations, :source => "sink"
  has_many :actors, -> { order("re_artifact_relationships.position") },:through => :actors_relations, :source => "sink"
  has_many :dependency, -> { order("re_artifact_relationships.position") }, :through => :dependency_relations, :source => "sink"
  has_many :conflict, -> { order("re_artifact_relationships.position") }, :through => :conflict_relations, :source => "sink"
  has_many :rationale, -> { order("re_artifact_relationships.position") }, :through => :rationale_relations, :source => "sink"
  has_many :refinement, -> { order("re_artifact_relationships.position") }, :through => :refinement_relations, :source => "sink"
  has_many :part_of, -> { order("re_artifact_relationships.position") }, :through => :part_of_relations, :source => "sink"
  has_many :diagram, -> { order("re_artifact_relationships.position") }, :through => :diagram_relations, :source => "sink"

  ###
  has_many :sources, -> { order("re_artifact_relationships.position") }, :through => :traces_as_sink
  has_one  :parent,   :through => :parent_relation,  :source => "source"

  has_many :re_artifact_properties_versions

  acts_as_customizable

  acts_as_watchable
  acts_as_attachable({:delete_permission => :edit_requirements, :view_permission => :view_requirements})

  acts_as_event(
    :title => Proc.new { |o|
      "#{l(:re_artifact)}: #{o.name}"
    },
    :description => Proc.new { |o|
      "#{o.description}"
    },
    :datetime => :updated_at,
    :url => Proc.new { |o|
      {:controller => 're_artifact_properties', :action => 'show', :id => o.id}
    }
  )

  acts_as_activity_provider(
    :type => 're_artifact_properties',
    :timestamp => "#{ReArtifactProperties.table_name}.updated_at",
    :author_key => "#{ReArtifactProperties.table_name}.updated_by",
    :scope => joins([:project, :user]),
    :permission => :edit_requirements
  )

  # workaround such that the a project can be deleted flawlessly from Redmine
  def destroy
    if self.artifact_type == "Project"
      relationships_as_source.each { |r| r.destroy }
      delete
    else
      super
    end
  end

  def updated_on
    updated_at
  end

  def created_on
    created_at
  end

  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :user, :foreign_key => 'updated_by'
  belongs_to :artifact, :polymorphic => true, :dependent => :destroy
  belongs_to :responsible, :class_name => 'User', :foreign_key => 'responsible_id'
  belongs_to :re_status

  # attributes= and artifact_attributes are overwritten to instantiate
  # the correct artifact_type and use nested attributes for re_artifact_properties
  accepts_nested_attributes_for :artifact

  def attributes=(attributes = {})
    self.artifact_type = attributes[:artifact_type] if attributes[:artifact_type].present?
    super
  end

  validates :name, :length => {:minimum => 3, :maximum => 100}
  validates :project, :presence => true
  validates :created_by, :presence => true
  validates :updated_by, :presence => true
  validates :parent, :presence => true, if: ->(a) { a.artifact_type != "Project" }
  validates :artifact_type, :presence => true,
            :inclusion => { :in => ReArtifactPropertiesTypes.re_artifact_types_all }

  #TODO
  validates_associated :parent_relation
  validates :parent_relation, :presence => true, if: ->(a) { a.artifact_type != "Project" }


  # Returns true if usr or current user is allowed to view the artifact
  def visible?(usr=nil)
    (!usr.nil? && usr.allowed_to?(:view_requirements, self.project)) || User.current.allowed_to?(:view_requirements, self.project)
  end

  # Returns the users that should be notified
  def notified_users
    User.active.where("(mail_notification='all') OR (id IN (?))", [created_by, updated_by]).to_a.select { |user| visible?(user) }
  end

  # Returns the email addresses that should be notified
  def recipients
    notified_users.collect(&:mail)
  end

  def self.available_artifact_types
    all.group(:artifact_type).pluck(:artifact_type)
  end

  def position
    parent_relation.try(:position) || 0
  end

  def status
    re_status.to_s
  end

  def gather_children
    # recursively gathers all children for the given artifact
    children = []
    self.children.each { |child| children |= [child, child.gather_children] }

    children.flatten
  end

  def parent_id
    parent.try(:id)
  end

  def siblings
    self.parent.children
  end

  def move(new_parent, insert_position)
    self.parent = new_parent
    self.parent_relation.position = insert_position == 0 ? 1 : insert_position + 1
    self.parent_relation.save
    self.save
  end

  def has_acceptance_criteria?
    self.artifact_type != 'ReSection'
  end

  def create_version
    return if destroyed?

    re_artifact_properties_version = ReArtifactPropertiesVersion.create_from(self)

    self.update_column(:current_version, re_artifact_properties_version.version)
  end
end