class EasyNestedListProjectWrapper
  include Redmine::I18n
  
  attr_accessor :project, :options 

  def initialize(project, options = {})
    @project = project
    @options = options
  end

  def self.render(project, options = {})
    new(project, options).decorate
  end

  def decorate
    h.content_tag :label, box + (options[:label_text] || text), class: 'inline'
  end

  def cbx_options
    {
      class: cbx_classes,
      id: nil
    }
  end

  def cbx_name
    'projects[]'
  end

  def cbx_classes
    return @cbx_classes if @cbx_classes

    @cbx_classes = 'cbx-project'
    @cbx_classes = ' cbx-root-project' if project.root?
    @cbx_classes << ' ' + project.ancestors.collect{|ancestor| "cbx-parent-project-#{ancestor.id}"}.join(' ')
    @cbx_classes
  end

  def text
    return @text if @text

    labels = [project.to_s]
    if !project.leaf? && project.descendants.active.exists?
      sbp_link = h.link_to " #{l(:button_check_subprojects)}/#{l(:button_uncheck_subprojects)}", 'javascript:void(0)', onclick: "toggleCheckboxesBySelector('input.cbx-parent-project-#{project.id}')", title: "#{l(:button_check_subprojects)}/#{l(:button_uncheck_subprojects)}", class: 'icon icon-checked'
      labels << sbp_link
    end

    @text = labels.join(' ').html_safe
  end

  def box
    h.check_box_tag options[:cbx_name] || cbx_name, project.id, false, cbx_options.merge(options[:cbx_options] || {})
  end

  private

  def h
    ActionController::Base.helpers
  end
 
end
