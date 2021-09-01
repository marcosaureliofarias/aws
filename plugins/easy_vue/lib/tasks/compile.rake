require_relative "../easy_vue/internals"
namespace :easy_vue do
  desc <<-END_DESC
    Install NPM dependencies
    Build `bundle.js` with easy_vue

    Example:
      bundle exec rake easy_vue:compile
  END_DESC
  task :compile do
    Dir.chdir Rails.root.to_s do
      EasyVue.compile
    end
  end
end
#if Rake::Task.task_defined?("assets:precompile")
#  Rake::Task["assets:precompile"].enhance(["easy_vue:compile"]) do
#    prefix = task.application.original_dir == Rails.root.to_s ? "" : "app:"
#    Rake::Task["#{prefix}easy_vue:compile"].invoke
#  end
#else
#  Rake::Task.define_task("assets:precompile" => ["easy_vue:compile"])
#end
