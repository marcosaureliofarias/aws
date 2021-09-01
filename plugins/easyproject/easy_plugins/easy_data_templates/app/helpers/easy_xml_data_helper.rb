module EasyXmlDataHelper
  
  def project_selection_tree(projects)
    tree = '<ul id="project-selection-tree">'
    tree << "<li><strong><label>#{check_box_tag('', '', false, :id => 'project-select-all')} #{l(:label_project_all)}</label></strong></li>"
    parents = []
    projects.each do |project|
      parents.each do |parent|
        if !project.is_descendant_of?(parent)
          parents.delete(parent)
          tree << '</ul></li>'
        end
      end
      tree << "<li><label>#{check_box_tag('projects[]', project.id)} #{project.name}</label>"
      if project.leaf?
        tree << '</li>'
      else
        parents << project
        tree << '<ul>'
      end
    end
    (tree << '</ul>').html_safe
  end
  
end