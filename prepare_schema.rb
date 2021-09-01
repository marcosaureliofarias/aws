require 'fileutils'
require 'digest/md5'

adapter = ENV['ADAPTER'].to_s
tmp_path = ENV['TMP_PATH'].to_s
tmp_path = (!File.exist?(tmp_path) && File.exist?('/tmp')) ? '/tmp' : 'tmp'
lockfile = File.join(tmp_path, "lock_migrations_#{adapter}.lock")
cache_prefix = 'dbcache'
schema_path = 'db/schema.rb'

if File.exist?(schema_path)
  puts 'Using schema from git'
else
  migrations = Dir['**/db/migrate/*.rb']
  #migrations.concat(Dir['**/db/data/*.rb'])
  #migrations << 'Gemfile.lock'
  md5 = Digest::MD5.new
  md5.update(adapter)
  migrations.each { |f| md5.update(File.binread(f)) }

  cache_file = File.join(tmp_path, "#{cache_prefix}-#{adapter}-#{md5.hexdigest}.cache")

  if File.exist?(cache_file) # schema was cached
    puts "Using cache #{cache_file}"
    FileUtils.cp(cache_file, schema_path)
  else
    lock_file = File.open(lockfile, File::RDWR|File::CREAT, 0644)
    begin
      puts 'Lock for migrations'
      lock_file.flock(File::LOCK_EX) # lock for other processes
      if !File.exist?(schema_path) # another process already did that for us
        # migrate
        system('bundle exec rake db:migrate')
        if($?.exitstatus != 0)
          puts "Something went wrong (task: db:migrate), exit code #{$?.exitstatus}"
        else
          system('bundle exec rake redmine:plugins:migrate')
          if ($?.exitstatus != 0) || !File.exist?(schema_path)
            puts "Something went wrong (task: redmine:plugins:migrate), exit code #{$?.exitstatus}"
          else
            FileUtils.cp(schema_path, cache_file)
            puts "Cached to #{cache_file}"
          end
        end
      end
    ensure
      puts 'Release lock'
      lock_file.close
    end
  end
end