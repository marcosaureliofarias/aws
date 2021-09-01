easy_extensions = Redmine::Plugin.installed?(:easy_extensions)

Dir[File.dirname(__FILE__) + '/lib/**/*.rb'].each { |file| require_dependency file }

if easy_extensions
  Rails.application.configure do
    config.assets.precompile << 'init_diagram.js'
  end
end

RedmineExtensions::Reloader.to_prepare do
  Redmine::AccessControl.map do |map|
    map.permission :manage_diagrams, { diagrams: [:index, :show, :save, :destroy, :bulk_destroy, :toggle_position, :generate] }, require: :loggedin, global: true
  end
end

ActiveSupport.on_load(:easyproject, yield: true) do
  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :diagrams, { controller: 'diagrams', action: 'index' },
              html: { class: 'icon icon-project', category: :solution_modules },
              caption: :'diagrams.label',
              if: Proc.new { User.current.allowed_to_globally? :manage_diagrams }
  end
end
