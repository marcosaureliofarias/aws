class ReSettingsController < RedmineReController
  menu_item :re

  before_action :get_artifact, only: [:edit, :update]
  before_action :initialize_artifact_order, only: [:new, :edit]
  before_action :initialize_relation_order, only: [:new, :edit]
  before_action :get_artifact_config, only: [:new, :edit]

  def new
    @project_artifact = ReArtifactProperties.new(project_params)
  end

  def edit
  end

  def update
    save_user_config
  end

  def create
    @project_artifact = ReArtifactProperties.create!(project_params)
    @project_artifact.create_version
    save_user_config
  end

private

  def project_params
    {
      project_id: @project.id,
      artifact_type: "Project",
      created_by: User.current.id,
      updated_by: User.current.id,
      artifact_id: @project.id,
      description: @project.description,
      name: @project.name
    }
  end

  def get_artifact
    @project_artifact = ReArtifactProperties.where({ project_id: @project.id, artifact_type: "Project"})
  end

  def get_artifact_config
    @re_statuses = ReStatus.where(project: @project)
    @plugin_description = ReSetting.get_plain("plugin_description", @project.id)

    @re_artifact_configs = {}
    @re_artifact_order.each do |artifact_type|
      configured_artifact = ReSetting.get_serialized(artifact_type, @project.id)
      if configured_artifact.nil?
        configured_artifact = {}
        configured_artifact['in_use'] = true
        configured_artifact['alias'] = artifact_type.underscore.gsub(/^re_/, '').humanize
        configured_artifact['color'] = artifact_type.to_s.classify.constantize::INITIAL_COLOR rescue next
        ReSetting.set_serialized(artifact_type, @project.id, configured_artifact)
      end
      @re_artifact_configs[artifact_type] = configured_artifact
    end
  end

  def initialize_relation_order
    types = ReRelationtype.where(project_id: @project.id).to_a
    order = ReSetting.get_serialized("relation_order", @project.id)
    unless(order.nil?)
      types.sort_by!{|type| order.find_index(type.relation_type)}
    end
    @re_relation_types = types
  end

  def initialize_artifact_order
    configured_artifact_types = []

    # Get Serialized order array artifact types:
    stored_settings = ReSetting.get_serialized("artifact_order", @project.id)

    @project_hierarchy = ReSetting.find_or_create_by(name: 'project_hierarchy', project: @project)
    @display_requirement_id = ReSetting.find_or_create_by(name: 'display_requirement_id', project: @project)

    # Put it into the empty configured_artifact_types array
    configured_artifact_types |= stored_settings if stored_settings.present?

    configured_artifact_types |= ReSetting::ARTIFACT_TYPES.clone

    ReSetting.set_serialized("artifact_order", @project.id, configured_artifact_types)
    @re_artifact_order = configured_artifact_types
  end

  def save_user_config
    new_artifact_order = ActiveSupport::JSON.decode(params[:re_artifact_order] || '{}')
    new_relation_order = ActiveSupport::JSON.decode(params[:re_relation_order] || '{}')

    ReSetting.set_serialized("artifact_order", @project.id, new_artifact_order)
    ReSetting.set_serialized("relation_order", @project.id, new_relation_order)

    new_artifact_configs = params[:re_artifact_configs] || {}
    new_artifact_configs.each_pair do |k,v|
      # disabled checkboxes do not send a key/value pair
      v['in_use'] = v.has_key? 'in_use'
      v['printable'] = v.has_key? 'printable'
      ReSetting.set_serialized(k, @project.id, v)
    end

    # Get existing
    new_relation_configs = params[:re_relation_configs] || {}

    # Add new relations
    if params[:config].present? && params[:config][:re_relationtypes].present?
      params[:config][:re_relationtypes].each_pair do |k, new_relation|
        new_relation_configs = new_relation_configs.merge({ k => new_relation })
      end
    end

    unless new_relation_configs.nil?

      new_relation_configs.each_pair do |k, v|
        if v['id'].blank?
          r = ReRelationtype.new
          if v[:alias_name].empty?
            v[:alias_name] = "NewRelation"
          end
          r.relation_type = v[:alias_name] # on i the type was created the alias name will be set
          r.is_system_relation = 0
        else
          r = ReRelationtype.find_or_create_by(id: v['id'])
        end

        if r.is_system_relation == 0
          r.in_use = (v[:in_use] == "1" || v[:in_use] == "yes")
          r.is_directed = (v[:is_directed] == "1" || v[:is_directed] == "yes")
        end
        r.alias_name = v[:alias_name]
        r.color = v[:color]
        r.project_id = @project.id

        if r.is_system_relation == "1"
          r.save
        else
          if v[:destroy] == "1"

            n = ReArtifactRelationship.where(relation_type: r.relation_type)
            n.each do |relation|
              artifact = ReArtifactProperties.find(relation.source_id)
              if (artifact.project_id == r.project_id)
                ReArtifactRelationship.destroy(relation.id)
              end
            end

            ReRelationtype.destroy(r.id)
          else
            r.save
          end
        end
      end
    end #unless

    # Get existing
    new_status_configs = params[:re_status_configs] || {}

    # Add new statuses
    if params[:config].present? && params[:config][:re_statuses].present?
      params[:config][:re_statuses].each_pair do |k, new_status|
        new_status_configs = new_status_configs.merge({ k => new_status })
      end
    end

    unless new_status_configs.nil?
      new_status_configs.each_pair do |k, v|
        if v['id'].blank?
          status = ReStatus.new
          if v[:alias_name].empty?
            v[:alias_name] = "NewStatus"
          end
          status.label = v[:alias_name] # on i the type was created the alias name will be set
        else
          status = ReStatus.find_or_create_by(id: v['id'])
        end
        status.alias_name = v[:alias_name]
        status.color = v[:color]
        status.project_id = @project.id

        if v[:destroy] == "1"
          status.destroy
        else
          status.save
        end
      end
    end

    project_hierarchy = ReSetting.find_or_initialize_by(name: 'project_hierarchy', project: @project)
    project_hierarchy.value = params[:re_settings_project_hierarchy]
    project_hierarchy.save

    project_hierarchy = ReSetting.find_or_initialize_by(name: 'display_requirement_id', project: @project)
    project_hierarchy.value = params[:re_settings_display_requirement_id]
    project_hierarchy.save

    @re_artifact_order = ReSetting.get_serialized("artifact_order", @project.id)
    ReSetting.set_serialized("unconfirmed", @project.id, false)

    flash[:notice] = t(:re_configs_saved)

    redirect_to controller: "requirements", action: "index", project_id: @project.id
  end

end
