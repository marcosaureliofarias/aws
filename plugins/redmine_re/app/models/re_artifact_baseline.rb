class ReArtifactBaseline < ActiveRecord::Base
  belongs_to :project

  has_many :re_artifact_baselines_re_artifact_properties_versions, dependent: :destroy
  has_many :re_artifact_properties_versions, through: :re_artifact_baselines_re_artifact_properties_versions
  has_many :re_artifact_properties, through: :project
  has_many :included_re_artifact_properties, through: :re_artifact_properties_versions, source: :re_artifact_properties, class_name: 'ReArtifactProperties'

  scope :ordered, -> { order(created_at: :desc) }
  scope :with_project, ->(project) { where(project: project) }

  validates :name, presence: true, uniqueness: { scope: :project_id, case_sensitive: true }

  def to_s
    name
  end

  def revert!
    re_artifact_properties_versions.each(&:revert_artifact!)

    hide_excluded_re_artifact_properties
  end

  def hide_excluded_re_artifact_properties
    excluded_re_artifact_properties.each do |re_artifact_properties|
      re_artifact_properties.relationships_as_source.destroy_all
      re_artifact_properties.relationships_as_sink.destroy_all
    end
  end

  def excluded_re_artifact_properties
    re_artifact_properties.where.not(id: included_re_artifact_properties)
  end

  def bind_current_versions
    self.re_artifact_properties_version_ids = current_version_ids
  end

  def current_version_ids
    ReArtifactPropertiesVersion
      .with_project(project)
      .with_parent_relation_or_parent
      .joins(:re_artifact_properties)
      .where('re_artifact_properties.current_version = re_artifact_properties_versions.version')
      .group(:re_artifact_properties_id, 're_artifact_properties_versions.id')
      .pluck(Arel.sql('distinct(re_artifact_properties_versions.id)'))
  end
end
