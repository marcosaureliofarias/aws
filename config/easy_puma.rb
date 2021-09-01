ENV["RAILS_MAX_WORKERS"] ||= "1"
ENV["RAILS_MAX_THREADS"] ||= "1"

workers ENV["RAILS_MAX_WORKERS"]
threads 1, ENV["RAILS_MAX_THREADS"]

preload_app!

rackup      DefaultRackup
environment ENV['RAILS_ENV'] || 'production'
plugin "tmp_restart"

worker_timeout 600

directory File.expand_path __dir__, ".."
bind 'tcp://0.0.0.0:3000'

on_worker_boot do
  ActiveRecord::Base.establish_connection
end

