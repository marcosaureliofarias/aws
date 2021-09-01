module EasyMonitoring
  class Metadata < Hash

    def self.configure(&block)
      yield instance
    end

    def self.instance
      @@instance ||= new
    end

    def host_name
      self['host_name']
    end

    def method_missing(name, *args)
      name_string = name.to_s
      if name_string.chomp!("=")
        self[name_string] = args.first
      else
        bangs = name_string.chomp!("!")

        if bangs
          self[name_string].presence || raise(KeyError.new(":#{name_string} is blank"))
        else
          self[name_string]
        end
      end
    end

    def respond_to_missing?(name, include_private)
      true
    end

  end
end
