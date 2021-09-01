class ReArtifactPropertiesVersion < ActiveRecord::Base
  include ReArtifactPropertiesVersions::Diff

  serialize :issue_ids,            Array
  serialize :custom_fields,        Array
  serialize :sink_relationships,   Array
  serialize :source_relationships, Array

  STORE_ATTRIBUTES = %w[
    artifact_type
    project_id
    name
    responsible_id
    re_status_id
    description
    acceptance_criteria
    issue_ids
    sink_relationships
    source_relationships
    custom_fields
  ]

  belongs_to :re_artifact_properties, with_deleted: true
  belongs_to :user, optional: true

  scope :with_project, ->(project) { joins(:re_artifact_properties).where(re_artifact_properties: { project_id: project.id }) }
  scope :ordered, -> { order(version: :desc) }
  scope :with_parent_relation,           -> { left_outer_joins(re_artifact_properties: :parent_relation) }
  scope :with_parent_child_relation,     -> { with_parent_relation.where(re_artifact_relationships: { relation_type: 'parentchild' }) }
  scope :with_parent,                    -> { with_parent_relation.where(artifact_type: 'Project') }
  scope :with_parent_relation_or_parent, -> { with_parent_child_relation.or(with_parent) }

  validates :version, presence: true, uniqueness: { scope: :re_artifact_properties_id, case_sensitive: true }

  delegate :name, to: :user, prefix: true

  def timestamp_to_s
    created_at.to_date
  end

  def next_version
    re_artifact_properties.re_artifact_properties_versions.ordered.first&.version.to_i.next
  end

  def increment_version
    self.version = next_version
  end

  def self_and_siblings
    ReArtifactPropertiesVersion.where(re_artifact_properties_id: re_artifact_properties_id)
  end

  def revert_artifact!
    re_artifact_properties = ReArtifactProperties.with_deleted.find_by(id: re_artifact_properties_id)
    re_artifact_properties.recover if re_artifact_properties.deleted?
    re_artifact_properties = prepare_re_artifact_properties(re_artifact_properties)
  end

  def prepare_re_artifact_properties(re_artifact_properties)
    self.class.set_attributes(self, re_artifact_properties).tap do |object|
      object.current_version = version
      object.save
    end
  end

  def self.create_from(re_artifact_properties)
    re_artifact_properties.re_artifact_properties_versions.build.tap do |object|
      object = set_attributes(re_artifact_properties, object)
      object.increment_version
      object.user = User.current
      object.save
    end
  end

  def self.set_attributes(source, target)
    self::STORE_ATTRIBUTES.each do |attribute|
      next unless source.respond_to?(attribute) && target.respond_to?("#{attribute}=")

      begin
        target.send("#{attribute}=", source.reload.send(attribute))
      rescue ActiveRecord::RecordNotFound
      end
    end

    target
  end
end
