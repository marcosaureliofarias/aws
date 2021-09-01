require 'easy_mindmup/easy_mindmup'

class AddDefaultWbsPrintableTemplate < RedmineExtensions::Migration

  def up
    return unless EasyMindmup.easy_printable_templates?

    plugin = Redmine::Plugin.find('easy_wbs')
    path = File.join(plugin.directory, 'app', 'views', 'easy_wbs', 'printable_templates', 'default.html')

    EasyPrintableTemplate.create_from_view!(
      {
        'name' => 'Easy WBS (default)' ,
        'pages_orientation' => 'landscape',
        'pages_size' => 'a4',
        'category' => 'easy_wbs',
      },
      { template_path: path })
  end

  def down
    return unless EasyMindmup.easy_printable_templates?

    EasyPrintableTemplate.where(category: 'easy_wbs').destroy_all
  end

end
