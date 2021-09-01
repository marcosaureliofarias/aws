class ReSetting < ActiveRecord::Base
  belongs_to :project

  has_many :re_artifact_properties, through: :project
  has_many :re_artifact_issues, through: :re_artifact_properties, source: :issues, class_name: 'Issue'
  has_many :re_realizations, through: :re_artifact_properties

  validates :name, :uniqueness => { :scope => :project_id, :case_sensitive => true }

  after_commit :unbind_issues_outside_hierarchy, if: :project_hierarchy?

  ARTIFACT_TYPES = ReArtifactPropertiesTypes.re_artifact_types
  PROJECT_HIERARCHY_TYPES = %w[none descendants hierarchy all]

  def project_hierarchy?
    name == 'project_hierarchy'
  end

  def unbind_issues_outside_hierarchy
    ReRealization
      .joins(re_artifact_properties: :project)
      .where(issue: project.issues)
      .where.not(re_artifact_properties: { project: project_hierarchy })
      .destroy_all

    re_realizations
      .where(issue: re_artifact_issues.where.not(project: project_hierarchy))
      .destroy_all
  end

  def project_hierarchy
    Project.in_requirements_hierarchy_of(project)
  end

  def self.display_requirement_id?(project)
    find_by(name: 'display_requirement_id', project: project)&.value == '1'
  end

  def self.get_plain(name, project_id)
    # reads a project specific setting
    # the setting will be returned in plain text

    load_setting(name, project_id)
  end

  def self.set_plain(name, project_id, value)
    # creates a project specific setting
    # the setting must be plain text
    setting = find_or_create_by(name: name, project_id: project_id)
    setting.value = value.to_s
    setting.save!

    setting.value
  end

  def self.set_serialized(name, project_id, object)
    # reads a project specific setting
    # the setting will be returned as object
    json_string = ActiveSupport::JSON.encode(object)
    self.set_plain(name, project_id, json_string)
  end

  def self.get_serialized(name, project_id)
    # creates a project specific setting
    # the setting should be a (JSON serializable) object (hash, array and so on)
    json_string = self.get_plain(name, project_id)
    ActiveSupport::JSON.decode(json_string) unless json_string.nil?
  end

  def self.active_re_artifact_settings(project_id)
    order = ReSetting.get_serialized("artifact_order", project_id)
    generate_active_settings_hash(order, project_id)
  end

  def self.active_re_relation_settings(project_id)
    order = ReSetting.get_serialized("relation_order", project_id)
    generate_active_settings_hash(order, project_id)
  end

  def self.force_reconfig
    Project.all.each do |project|
      if (project.enabled_module_names.include? 'requirements')
        ReSetting.set_serialized("unconfirmed", project.id, true)
      end
    end
  end

  def self.project_hierarchy_types_to_list
    PROJECT_HIERARCHY_TYPES.map do |type|
      [I18n.t("re_settings.project_hierarchy_types.#{type}"), type]
    end
  end

  private

  def self.load_setting(name, project_id)
    setting = find_by(name: name, project_id: project_id)
    setting.value unless setting.nil?
  end

  def self.generate_active_settings_hash(order, project_id)
    active_settings = {}
    order.to_a.each do |name|
      setting = self.get_serialized(name, project_id)
      active_settings[name] = setting if setting && setting["in_use"]
    end
    active_settings
  end

end
