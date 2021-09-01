Rys::PluginsManagement.all(systemic: true) do |plugin|
  helpers_dir = plugin.root.join('spec/support')
  next if !helpers_dir.exist?

  Dir.glob(helpers_dir.join('**/*.rb')) do |file|
    require file
  end
end
