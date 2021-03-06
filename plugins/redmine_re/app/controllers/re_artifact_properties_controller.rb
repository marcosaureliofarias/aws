include WatchersHelper

class ReArtifactPropertiesController < RedmineReController
  menu_item :re

  helper :watchers
  helper :attachments
  include AttachmentsHelper

  helper :custom_fields
  include CustomFieldsHelper

  before_action :load_re_artifact_properties, only: [:history, :revert_to_version]
  before_action :load_re_artifact_properties_version, only: [:revert_to_version]

  def new
    @re_artifact_properties = ReArtifactProperties.new
    @artifact_type = params[:artifact_type]
    # create a typed artifact instance in re_artifact_properties.artifact
    # (e.g. ReUseCase or ReTask)
    @re_artifact_properties.artifact_type = @artifact_type.camelcase
    @re_artifact_properties.artifact = @artifact_type.camelcase.constantize.new
    @re_artifact_properties.project = @project

    begin
      @re_artifact_properties.artifact.new_hook(params)
    rescue NoMethodError
      logger.debug("#{@re_artifact_properties.artifact.class} does not implement new hook")
    end
    @secondary_user_profiles = []
    @user_profiles = ReArtifactProperties.where(artifact_type: 'ReUserProfile', project_id: @project.id)

    unless params[:sibling_artifact_id].blank?
      sibling = ReArtifactProperties.find(params[:sibling_artifact_id])
      if sibling && sibling.parent
        @parent_artifact_id = sibling.parent.id
        @parent_relation_position = sibling.parent_relation.position + 1
      else
        @parent_artifact_id = ReArtifactProperties.where({
                                                             :project_id => @project.id,
                                                             :artifact_type => "Project"}
        ).limit(1).first.id
        begin
          @parent_relation_position = parent.child_relations.last.position + 1
        rescue # child_relations.last = nil -> creating the first artifact
          @parent_relation_position = 1
        end
      end
    end

    unless params[:parent_artifact_id].blank?
      parent = ReArtifactProperties.find(params[:parent_artifact_id])
      @parent_artifact_id = parent.id
      begin
        @parent_relation_position = parent.child_relations.last.position + 1
      rescue NoMethodError # child_relations.last = nil -> creating the first artifact
        @parent_relation_position = 1
      end
    end
    initialize_tree_data
  end

  def create
    @re_artifact_properties = ReArtifactProperties.new
    @artifact_type = params[:re_artifact_properties][:artifact_type]
    #@re_artifact_properties.artifact = @artifact_type.camelcase.constantize.new
    #@re_artifact_properties.attributes = params[:re_artifact_properties]
    @re_artifact_properties.attributes = re_artifact_properties_params
    @re_artifact_properties.save_attachments(params[:attachments] || (params[:re_artifact_properties] && params[:re_artifact_properties][:uploads]))

    @added_issue_ids = params[:issue_id]
    @added_relations = params[:new_relation]

    @issues = @re_artifact_properties.issues

    # attributes that cannot be set by the user
    # @re_artifact_properties.project_id = @project.id
    @re_artifact_properties.created_at = Time.now
    @re_artifact_properties.updated_at = Time.now
    @re_artifact_properties.created_by = User.current.id
    @re_artifact_properties.updated_by = User.current.id

    # relation related attributes
    unless params[:parent_artifact_id].blank? || params[:parent_relation_position].blank?
      @re_artifact_properties.parent = ReArtifactProperties.find(params[:parent_artifact_id])
      logger.debug("ReArtifactProperties.create => parent_relation: #{@re_artifact_properties.parent_relation.inspect}")
      @parent_artifact_id = params[:parent_artifact_id]
      @parent_relation_position = params[:parent_relation_position]
      session[:expanded_nodes] << params[:parent_artifact_id].to_i
    end

    if @re_artifact_properties.save
      if Setting.notified_events.include?('issue_added')
        # we cannot add custom notifications for artifacts
        Mailer.deliver_artifact_add(@re_artifact_properties)
      end

      render_attachment_warning_if_needed(@re_artifact_properties)
      @re_artifact_properties.parent_relation.position = params[:parent_relation_position].to_i
      handle_relations_for_new_artifact params, @re_artifact_properties.id
      update_related_issues params

      if @project.enabled_module_names.include? 'diagrameditor'
        update_related_diagrams params, @re_artifact_properties
      end

      #set new artifact it to params array
      my_params = params
      my_params[:id] = @re_artifact_properties.id

      begin
        @artifact_specific_variables = @re_artifact_properties.artifact.create_hook(my_params)
      rescue NoMethodError
        logger.debug("#{@re_artifact_properties.artifact.class} does not implement create hook")
      end
      redirect_to @re_artifact_properties, :notice => t(:re_artifact_properties_created)
    else
      logger.debug("ReArtifactProperties.create => Errors: #{@re_artifact_properties.errors.inspect}")
      initialize_tree_data
      render :new
    end
  end

  def re_artifact_properties_params
    params.require(:re_artifact_properties).permit(:artifact_type, :project_id, :name, :responsible_id, :re_status_id, :description, :acceptance_criteria, artifact_attributes: [:start, :end, :frequency, :difficult], custom_field_values: [re_artifact_properties_custom_field_ids] )
  end

  def re_artifact_properties_custom_field_ids
    ReArtifactPropertiesCustomField.pluck(:id).map(&:to_s)
  end

  def show
    @re_artifact_properties = ReArtifactProperties.find(params[:id])
    @artifact_type = @re_artifact_properties.artifact_type

    session[:visualization_type]=params[:visualization_type]

    if @artifact_type == "Project"
      redirect_to :controller => 'requirements', :action => 'index', :project_id => @project.id
    else
     @artifact_color = @re_artifact_settings[@artifact_type]['color']
     @lighter_artifact_color = calculate_lighter_color(@artifact_color)

     @issues = @re_artifact_properties.issues
     @test_cases = gather_test_cases_from_issues(@issues)

     # Remove Comment (Initiated via GET)
     if User.current.allowed_to?(:administrate_requirements, @project)
        unless params[:deletecomment_id].blank?
          comment = Comment.find(params[:deletecomment_id])
          comment.destroy unless comment.nil?
        end
     end

     retrieve_previous_and_next_sibling_ids
     initialize_tree_data
   end

  end

  def retrieve_previous_and_next_sibling_ids
    position_id = @re_artifact_properties.parent ? Hash[@re_artifact_properties.parent.child_relations.collect { |s| [s.position, s.sink_id] }] : {}
    my_position = @re_artifact_properties.try(:position) || 0
    @artifact_count = position_id.size
    position_id.each_key do |pos| # ruby >= 1.9.2 uses a sorted hash such that the following works
      @previous_re_artifact_properties_id = position_id[pos] unless pos >= my_position
      @next_re_artifact_properties_id ||= position_id[pos] if pos > my_position
    end
  end

  def edit
    @re_artifact_properties = ReArtifactProperties.find(params[:id])
    @artifact_type = @re_artifact_properties.artifact_type
    @re_artifact_properties.save_attachments(params[:attachments] || (params[:re_artifact_properties] && params[:re_artifact_properties][:uploads]))
    @issues = @re_artifact_properties.issues

    if @project.enabled_module_names.include? 'diagrameditor'
      @relation_to_diagrams = ReArtifactRelationship.find_by(source_id: @re_artifact_properties.i, relation_type: 'diagram')
      @related_diagrams = ConcreteDiagram.where(id: @relation_to_diagrams.sink_id) unless @relation_to_diagrams.nil?
    end

    begin
      @artifact_specific_variables = @re_artifact_properties.artifact.edit_hook(params)
    rescue NoMethodError
      logger.debug("#{@re_artifact_properties.artifact.class} does not implement edit hook")
    end

    # Remove Comment (Initiated via GET)
    if User.current.allowed_to?(:administrate_requirements, @project)
      unless params[:deletecomment_id].blank?
        comment = Comment.find(params[:deletecomment_id])
        comment.destroy unless comment.nil?
      end
    end

    initialize_tree_data
  end

  def new_comment
     @re_artifact_properties = ReArtifactProperties.find(params[:id])

     # Add Comment
     comment = nil
     unless params[:comment].blank? && params[:comment] != ""
       comment = Comment.new
       comment.comments = params[:comment]
       comment.author = User.current
       @re_artifact_properties.comments << comment
       comment.save

       redirect_to @re_artifact_properties
     end

  end

  def update
    @re_artifact_properties = ReArtifactProperties.find(params[:id])
    @re_artifact_properties.save_attachments(params[:attachments] || (params[:re_artifact_properties] && params[:re_artifact_properties][:uploads]))

    @re_artifact_properties.attributes = re_artifact_properties_params

    @issues = @re_artifact_properties.issues

    # attributes that cannot be set by the user
    @re_artifact_properties.updated_at = Time.now
    @re_artifact_properties.updated_by = User.current.id

    # Remove related issues (Refresh will be done later)
    @re_artifact_properties.issues = []

    saved = @re_artifact_properties.save

    # Add Comment
    comment = nil
    unless params[:comment].blank?
      comment = Comment.new
      comment.comments = params[:comment]
      comment.author = User.current
      @re_artifact_properties.comments << comment
      comment.save
    end

    # Update related issues
    update_related_issues params

    # Update related diagrams if diagrameditor is enabled
    if @project.enabled_module_names.include? 'diagrameditor'
      update_related_diagrams params, @re_artifact_properties
    end

    #add/update actors
    begin
      @re_artifact_properties.artifact.create_hook(params)
    rescue NoMethodError
      logger.debug("#{@re_artifact_properties.artifact.class} does not implement create hook")
    end

    @artifact_type = @re_artifact_properties.artifact_type

    initialize_tree_data
    handle_relations params

    if saved
      if Setting.notified_events.include?('issue_updated')
        # we cannot add custom notifications for artifacts
        Mailer.deliver_artifact_edit(@re_artifact_properties, comment)
      end

      redirect_to @re_artifact_properties, :notice => t(:re_artifact_properties_updated)
    else
      render :action => 'edit'
    end
  end

  def handle_relations params
    unless params[:new_relation].nil?
      params[:new_relation].each do |id, content|
        if (content['_destroy'] == "true")
          # id is sink id of re_artifact_properties (artifact id)
          n = ReArtifactRelationship.find(id)
          n.destroy
        else
          # id is relation id, that should created,
          # content contains relation_type
          unless content['relation_type'].blank?
            content['relation_type'].each do |relationtype|
              new_relation = ReArtifactRelationship.new(:source_id => params[:id], :sink_id => id, :relation_type => relationtype)
              new_relation.save
            end
          end
        end
      end
    end

    # If all relations are created, then this need to be cleared
    @added_relations = nil

    @re_artifact_properties.create_version
  end

  def handle_relations_for_new_artifact params, new_source_artifact_id
    unless params[:new_relation].nil?
      params[:new_relation].each do |id, content|
        # id is relation id, that should created,
        # content contains relation_type
        unless content['relation_type'].blank?
          content['relation_type'].each do |relationtype|
            new_relation = ReArtifactRelationship.new(:source_id => new_source_artifact_id, :sink_id => id, :relation_type => relationtype)
            new_relation.save
          end
        end
      end
    end

    # If all relations are created, then this need to be cleared
    @added_relations = nil

    @re_artifact_properties.create_version
  end

  def update_related_issues params
    unless params[:issue_id].blank?

      params[:issue_id].delete_if { |v| v == "" }
      params[:issue_id].each do |iid|
        @re_artifact_properties.issues << Issue.find(iid)
      end
    end
  end

  def update_related_diagrams params, artifact_properties

      if params[:diagram_id].nil?
        new_diagram_ids = []
      else
        new_diagram_ids = params[:diagram_id].collect{|i| i.to_i}
      end

      old_related_diagrams = artifact_properties.related_diagrams

      old_diagram_ids = []

      old_related_diagrams.each do |dia|
        old_diagram_ids << dia[:id]
      end

      to_delete_diagrams = old_diagram_ids - new_diagram_ids
      to_add_diagrams = new_diagram_ids - old_diagram_ids

      #delete old relations
      to_delete_diagrams.each do |delete_diagram_id|
        delete_diagram = ReArtifactRelationship.destroy_all(:sink_id => delete_diagram_id, :source_id => artifact_properties.id, :relation_type => ReArtifactRelationship::SYSTEM_RELATION_TYPES[:dia])
      end

      #add new related diagrams
      to_add_diagrams.each do |diagram_id|

        new_relation = ReArtifactRelationship.new(:sink_id => diagram_id, :source_id => artifact_properties.id, :relation_type => ReArtifactRelationship::SYSTEM_RELATION_TYPES[:dia])
        if !new_relation.save
            logger.debug("Error:#{new_relation.errors.inspect}")
        end
      end #add each
  end

  def destroy
    gather_artifact_and_relation_data_for_destroying

    if @artifact_properties.artifact_type == "Project"
      flash[:error] = t(:re_delete_project_artifact_error)
    else
      @artifact_properties.destroy
      flash[:notice] = t(:re_deleted_artifact_and_moved_children, :artifact => @artifact_properties.name, :parent => @parent ? @parent.name : '')
    end

    redirect_to :controller => 'requirements', :action => 'index', :project_id => @project.id
  end

  def recursive_destroy
    gather_artifact_and_relation_data_for_destroying

    @children.each do |child|
      child.destroy
    end
    @artifact_properties.destroy

    flash[:notice] = t(:re_deleted_artifact_and_children, :artifact => @artifact_properties.name)
    redirect_to :controller => 'requirements', :action => 'index', :project_id => @project.id
  end

  def history
    @re_artifact_settings = ReSetting.active_re_artifact_settings(@project.id)
    @artifact_color = @re_artifact_settings[@re_artifact_properties.artifact_type]['color']
    @lighter_artifact_color = calculate_lighter_color(@artifact_color)
  end

  def revert_to_version
    @re_artifact_properties_version.revert_artifact!

    flash[:notice] = l('re_artifact_properties_version_reverted', version: @re_artifact_properties_version.version)

    redirect_to re_artifact_property_path(@re_artifact_properties)
  end

  def gather_artifact_and_relation_data_for_destroying
    @artifact_properties = ReArtifactProperties.find(params[:id])
    @relationships_incoming = @artifact_properties.relationships_as_sink
    @relationships_outgoing = @artifact_properties.relationships_as_source
    @parent = @artifact_properties.parent

    @children = gather_children(@artifact_properties)

    @relationships_incoming.to_a.delete_if { |x| x.relation_type.eql? "parentchild" }
    @relationships_outgoing.to_a.delete_if { |x| x.relation_type.eql? "parentchild" }
  end

  def how_to_delete
    method = params[:mode]
    @re_artifact_properties = ReArtifactProperties.find(params[:id])
    @relationships_incoming = @re_artifact_properties.relationships_as_sink
    @relationships_outgoing = @re_artifact_properties.relationships_as_source
    @parent = @re_artifact_properties.parent

    @children = gather_children(@re_artifact_properties)

    @relationships_incoming.to_a.delete_if { |x| x.relation_type.eql? "parentchild" }
    @relationships_outgoing.to_a.delete_if { |x| x.relation_type.eql? "parentchild" }

    initialize_tree_data

    if @re_artifact_properties.artifact_type == 'Project'
      render :delete_project_artifact
    else
      render :delete
    end

  end

  def autocomplete_artifact
    query = '%' + params[:artifact_name].gsub('%', '\%').gsub('_', '\_').downcase + '%'
    issues_for_ac = ReArtifactProperties.where('name LIKE ? AND project_id = ?', query, @project.id)
    list = '<ul>'
    issues_for_ac.each do |aprop|
      list << '<li ' + 'id='+aprop.id.to_s+'>'
      list << aprop.name.to_s+' ('+aprop.id.to_s+')'
      list << '</li>'
    end

    list << '</ul>'
    render plain: list
  end

  def remove_artifact_from_issue
    artifact_to_delete = ReArtifactProperties.find(params[:artifactid])
    issue = Issue.find(params[:issueid])
    issue.re_artifact_properties.delete(artifact_to_delete)
    redirect_to(:back)
  end

  # Ajax call
  def autocomplete_parent
    artifact = ReArtifactProperties.find(params[:id]) unless params[:id].blank?

    query = '%' + params[:parent_name].gsub('%', '\%').gsub('_', '\_').downcase + '%'
    parents = ReArtifactProperties.where('name LIKE ?', query)

    if artifact
      children = artifact.gather_children
      parents.delete_if { |p| children.include? p }
      parents.delete_if { |p| p == artifact }
    end

    list = '<ul>'
    for parent in parents
      list << render_autocomplete_artifact_list_entry(parent)
    end
    list << '</ul>'
    render plain: list
  end

  private

  # calculates a lighter color for the artifact headers show view
  # such that the text (hopefully) remains readable
  def calculate_lighter_color(hex_color_string)
    factor = 150
    r = hex_color_string[1, 2].to_i(16)
    g = hex_color_string[3, 2].to_i(16)
    b = hex_color_string[5, 2].to_i(16)

    rgb_spreading_and_a_bit = [r, g, b].max - [r, g, b].min + 20
    factor = rgb_spreading_and_a_bit > factor ? factor : rgb_spreading_and_a_bit

    r += factor
    g += factor
    b += factor
    r = r > 255 ? 255 : r
    g = g > 255 ? 255 : g
    b = b > 255 ? 255 : b
    "##{r.to_s(16) + g.to_s(16) + b.to_s(16)}"
  end

  # recursively gathers all children for the given artifact
  def gather_children(artifact)

    children = Array.new
    children.concat artifact.children
    return children if artifact.changed? || artifact.children.empty?
    for child in children
      children.concat gather_children(child)
    end
    children
  end

  # gather related test cases from issues with test case issue execution result
  # test case can be related to issue directly or through test plans
  def gather_test_cases_from_issues(issues)
    test_cases = []
    if @project && @project.module_enabled?(:test_cases) && User.current.allowed_to?(:view_test_cases, @project)
      issues.each do |issue|
        issue_test_cases = []

        # get test cases directly from issue
        if issue.safe_attribute?('test_case_ids')
          issue_test_cases |= issue.test_cases.to_a
        end

        # get test cases from test plans
        if issue.safe_attribute?('test_plan_ids')
          issue.test_plans.each { |test_plan| issue_test_cases |= test_plan.test_cases.to_a }
        end

        # get latest related test case issue execution results
        issue_test_cases.each do |test_case|
          tc_issue_execution = test_case.test_case_issue_executions.where(issue: issue).order(created_at: :desc).first
          test_cases << { issue: issue, test_case: test_case, test_case_issue_execution: tc_issue_execution }
        end
      end
    end
    test_cases
  end

  def load_re_artifact_properties
    @re_artifact_properties = ReArtifactProperties.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def load_re_artifact_properties_version
    @re_artifact_properties_version = ReArtifactPropertiesVersion.find(params[:re_artifact_properties_version_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
