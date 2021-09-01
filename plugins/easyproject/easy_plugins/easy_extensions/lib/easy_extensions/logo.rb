module EasyExtensions

  module Logo
    include ActiveSupport::Configurable
    config_accessor :path
    config_accessor :mark_path

    # Path to primary "full" logo
    # @return [String]
    def self.logo
      convert_logo_path(path)
    end

    # Path to square "mark" logo
    # @return [String]
    def self.logo_mark
      convert_logo_path(mark_path)
    end

    # Convert value of config to string path
    # @param [String, proc, nil] config
    # @return [String]
    def self.convert_logo_path(config)
      config.is_a?(Proc) ? config.call : config.to_s
    end

  end
end
