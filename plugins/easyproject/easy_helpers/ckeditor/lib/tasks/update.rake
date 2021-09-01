namespace :easyproject do

  desc <<-END_DESC
    Update ckeditor

    Example:
      bundle exec rake easyproject:update_ckeditor RAILS_ENV=production
  END_DESC

  def extract_zip(file, destination)
    FileUtils.mkdir_p(destination)

    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(destination, f.name)
        ftarget = File.dirname(fpath)
        FileUtils.mkdir_p(ftarget) unless File.exist?(ftarget)
        zip_file.extract(f, fpath) unless File.exist?(fpath)
      end
    end
  end

  def easy_plugins
    /plugins\/easy.*/
  end

  def get_version(file)
    version = File.read(file).scan(/^## CKEditor (\d.*)$/)
    raise "version number not found!" unless version
    version.first.join
  end

  def get_link(file)
    configuration = File.read(file)
    scan = configuration.scan(/^.*\(3\) (\S+).*$/)
    raise "build link not found!" unless scan
    URI.parse(scan.join)
  end

  task :update_ckeditor => :environment do
    puts 'preparing...'
    root = File.expand_path(File.join(__dir__, "../../assets/javascripts/ckeditor"))
    config = File.join(root, "build-config.js")
    changes = File.join(root, "CHANGES.md")
    raise "build-config.js not found!" unless File.exist?(config)
    raise "CHANGES.md not found!" unless File.exist?(changes)

    link = get_link(config)
    version = get_version(changes)
    puts "current version is: #{version}"
    puts 'downloading...'
    zip_path = File.join(root, "new_version.zip")
    File.binwrite(zip_path, open(link, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).read)

    begin
      raise "zip-file is empty!" if !File.exist?(zip_path) || File.zero?(zip_path)
      extract_zip(zip_path, root)
      new_path = File.join(root, 'ckeditor')
      new_changes = File.join(new_path, 'CHANGES.md')
      new_version = get_version(new_changes)
      puts "new version is: #{new_version}"
      if version == new_version && ENV['FORCE'].blank?
        raise "this is the lastest version"
      end
      puts 'updating...'

      (Dir.entries(root) - ['.', '..', 'ckeditor', 'config.js', 'plugins']).map{|dir| File.join(root, dir) }.each do |dir|
        FileUtils.rm_rf(dir)
      end
      plugins = File.join(root, 'plugins')
      (Dir.entries(plugins) - ['.', '..']).map{|dir| File.join(plugins, dir) }.each do |dir|
        if dir =~ easy_plugins
          # ignore
        else
          FileUtils.rm_rf(dir)
        end
      end

      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      main_js_path = File.join(new_path, 'ckeditor.js')
      main_js = File.binread(main_js_path)
      main_js.gsub!(/getUrl(.*?).js"/) do |x|
        "#{x[0..-2]}?#{timestamp}\""
      end
      File.binwrite(main_js_path, main_js)

      FileUtils.rm_rf(File.join(root, 'ckeditor', 'config.js'))
      FileUtils.rm_rf(File.join(root, 'ckeditor', 'samples'))
      FileUtils.cp_r(File.join(root, 'ckeditor'), File.expand_path("#{root}/.."))
    ensure
      FileUtils.rm_rf(zip_path)
      FileUtils.rm_rf(File.join(root, 'ckeditor'))
    end

    puts 'done'
  end

end