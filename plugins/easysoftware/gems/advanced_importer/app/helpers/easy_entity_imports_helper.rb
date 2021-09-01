module EasyEntityImportsHelper
  def entity_import_buttons
    output = ''
    EasyEntityImport.available_import_entities.each do |klass|
      e_name = klass.name.demodulize.underscore
      output << link_to(l("button_new_#{e_name}", default: e_name.humanize), new_easy_entity_imports_path(klass), class: "button-positive icon icon-import #{e_name.dasherize}", remote: true)
    end
    output.html_safe
  end

  def render_easy_entity_xml_nodes(nodes)
    nodes.elements.each do |child_nodes|
      yield(child_nodes)
      render_easy_entity_xml_nodes(child_nodes) do |x|
        yield(x)
      end
    end
  end
end