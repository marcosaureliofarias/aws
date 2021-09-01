# this block is runed once just after easyproject is started
# means after all plugins(easy) are initialized
# it is place for plain requires, not require_dependency
# it should contain hooks, permissions - base class in redmine is required thus is not reloaded
ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_buttons/easy_page_modules'
  require 'easy_buttons/permissions'
  require 'easy_buttons/internals'
  require 'easy_buttons/hooks'
  require 'easy_buttons/menus'
  require 'easy_buttons/proposer'

  # List of queries displayed to user on review pages(etc. my_page, sidebar, ...)
  EasyQuery.map do |query|
    query.register 'EasyButtonQuery'
  end

end

# this block is called every time rails are reloading code
# in development it means after each change in observed file
# in production it means once just after server has started
# in this block should be used require_dependency, but only if necessary.
# better is to place a class in file named by rails naming convency and let it be loaded automatically
# Here goes query registering, custom fields registering and so on
RedmineExtensions::Reloader.to_prepare do

  load 'easy_buttons/registration.rb'

  unless defined?(Rake)
    EasyButton.remove_deleted
    EasyButton.reload_buttons
  end

end
