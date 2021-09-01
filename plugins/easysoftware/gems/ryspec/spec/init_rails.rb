ENV['RAILS_ENV'] ||= 'test'

possible_app_dirs = [
  ENV['DUMMY_PATH'],
  Dir.pwd,
  File.join(Dir.pwd, 'test/dummy')
]

possible_app_dirs.each do |dir|
  next if !dir

  environment_rb = File.expand_path(File.join(dir, 'config/environment.rb'))
  if File.exist?(environment_rb)
    require environment_rb
    break
  end
end

if !defined?(Rails)
  abort("Rails wasn't found in any of these dirs: #{possible_app_dirs.join(', ')}")
end

if Rails.env.production?
  abort('The Rails environment is running in production mode!')
end
