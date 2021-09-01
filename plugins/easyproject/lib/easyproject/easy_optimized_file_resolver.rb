module ActionView
  class EasyOptimizedFileSystemResolver < OptimizedFileSystemResolver
    EXTENSIONS = { :formats => '.',  :handlers => '.' }

    def build_query(path, details)
      query = escape_entry(File.join(@path, path))

      if (details[:formats] == [:html])
        details = details.dup
        details[:handlers] = details[:handlers].dup & [:erb]
      end

      exts = EXTENSIONS.map do |ext, prefix|
        if details[ext] == :any
          "{#{prefix}*,}"
        else
          "{#{details[ext].compact.uniq.map { |e| "#{prefix}#{e}," }.join}}"
        end
      end.join

      query + exts
    end
  end
end