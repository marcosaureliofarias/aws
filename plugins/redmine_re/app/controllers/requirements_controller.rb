include ReApplicationHelper

class RequirementsController < RedmineReController
  menu_item :re

  before_action :find_re_artifact_properties, :find_re_status, only: :bulk_change_status

  def index
    initialize_tree_data
    @configured_description = ReSetting.get_plain('plugin_description', @project.id)
  end


  def delegate_tree_drop
    # The following method is called via if somebody drops an artifact on the tree.
    # It transmits the drops done in the tree to the database in order to last
    # longer than the next refresh of the browser.

    moved_artifact_id = params[:id]
    insert_position = params[:position].to_i
    parent_id = params[:parent_id]
    result = {}

    moved_artifact = ReArtifactProperties.find_by(id: moved_artifact_id)
    unless moved_artifact
      render json: result, status: 404
      return
    end

    new_parent = ReArtifactProperties.find_by(id: parent_id)
    unless new_parent
      render json: result, status: 404
      return
    end

    moved_artifact.move(new_parent, insert_position)
    result['status'] = 1
    result['insert_pos'] = 1

    render json: result
  end


  # saves the state of a node i.e. when you open or close a node in
  # the tree this state will be saved in the session
  # whenever you render the tree the rendering function will ask the
  # session for the nodes that are "opened" to render the children
  def tree
    node_id = params[:id].to_i
    if node_id == 0 && params[:id] != '#'
      render plain: "Missing artifact id.", status: 404
      return
    end

    case params[:mode]
      when 'data'
        render json: expand_node(node_id)
      when 'root'
        render json: create_tree(@project_artifact)
      when 'open'
        render plain: open_node(node_id)
      when 'close'
        render plain: close_node(node_id)
      else
        render plain: t('re_tree.mode.unknown'), status: 422
    end
  end


  # TODO: I don't have diagrameditor plugin
  def sendDiagramPreviewImage
    if @project.enabled_module_names.include? 'diagrameditor'
       path = File.join(Rails.root, "files")
       filename = "diagram#{params[:diagram_id]}.png"
       path = File.join(path, filename)
       send_file path, type: 'image/png', filename: filename
    end
  end

  def import
    attachment = params[:re_artifact_properties_attachment]

    if attachment.nil?
      flash[:error] = t(:re_artifact_properties_attachment_missing)
      redirect_to requirements_settings_project_path(@project)
      return
    end

    import = Imports::ReArtifactProperties.new(attachment.tempfile)
    import.run

    if import.valid?
      flash[:notice] = t(:re_artifact_properties_import_success)
    else
      flash[:error] = t(:re_artifact_properties_import_with_errors, errors: import.error_message)
    end

    flash.keep
    redirect_to controller: 'requirements', action: 'index'
  end

  def export
    export = Exports::ReArtifactProperties.new(ReArtifactProperties.where(project: @project))
    export.run

    respond_to do |format|
      format.xlsx do
        send_data export.to_stream.read, type: 'application/xlsx', filename: "#{t(:re_artifact_export)}.xlsx"
      end
    end
  end

  def bulk_change_status
    @re_artifact_properties.update_all(re_status_id: @re_status.id)

    render json: create_tree(@project_artifact.reload)
  end

  private

  def expand_node(node_id)
    session[:expanded_nodes] << node_id

    re_artifact_properties = ReArtifactProperties.find_by(id: node_id)
    return [] unless re_artifact_properties.present?

    re_artifact_properties.children.map { |child| create_tree(child) }
  end

  def open_node(node_id)
    session[:expanded_nodes] << node_id
    t('re_tree.node.opened', node_id: node_id)
  end


  def close_node(node_id)
    session[:expanded_nodes].delete(node_id)
    t('re_tree.node.closed', node_id: node_id)
  end

  def find_re_artifact_properties
    @re_artifact_properties = @project.re_artifact_properties.where(id: params[:ids])
  end

  def find_re_status
    @re_status = ReStatus.find(params[:status_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
