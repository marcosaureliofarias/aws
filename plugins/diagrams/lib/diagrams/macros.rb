Redmine::WikiFormatting::Macros.register do
  macro :include_diagram do |obj, args|
    id, title = args.first.to_s.split('--')
    return if title.nil?

    diagram = Diagram.find_by(id: id) || Diagram.create(title: title.parameterize)
    diagram.author ||= User.current
    diagram.project ||= @project
    diagram.save if diagram.changed?

    out = content_tag(:span, '')
    out << content_tag(:p, I18n.t('diagram_current_version', current_version: diagram.to_s))

    if !%w(html pdf txt).include?(params[:format])
      out << link_to(I18n.t('diagram_edit'), diagram_path(diagram, back_url: request.env['PATH_INFO']))
      out << " | #{I18n.t('diagram_versions')}: "

      toggle_position_path = toggle_position_diagram_path(diagram.id)
      out << select_tag('diagram-version', options_from_collection_for_select(DiagramVersion.to_list(diagram), :position, :position_with_timestamp), include_blank: true, 'toggle_position_path': toggle_position_path , style: 'width: auto')
    end

    return out if %w(pdf txt).include?(params[:format])

    if diagram.attachment_exists?
      out << content_tag('br')
      out << image_tag(diagram.attachment_base64)
    end

    out
  end
end