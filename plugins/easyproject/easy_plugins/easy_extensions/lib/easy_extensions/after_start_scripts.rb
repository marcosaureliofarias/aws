module EasyExtensions
  module AfterStartScripts

    mattr_accessor :registered_first, :registered, :registered_last
    self.registered_first = []
    self.registered       = []
    self.registered_last  = []

    def self.execute
      execute_collection registered_first
      execute_collection registered
      execute_collection registered_last
    end

    def self.add(options = {}, &block)
      return nil unless block

      if options[:first]
        registered_first << block
      elsif options[:last]
        registered_last << block
      else
        registered << block
      end
    end

    def self.execute_collection(collection)
      collection.each do |b|
        b.call if b.respond_to?(:call)
      end
    end

  end

  module AfterInstallScripts

    mattr_accessor :registered_first, :registered, :registered_last
    self.registered_first = []
    self.registered       = []
    self.registered_last  = []

    def self.execute
      execute_collection registered_first
      execute_collection registered
      execute_collection registered_last

      EasyExtensions.puts "All after install scripts executed."
    end

    def self.add(options = {}, &block)
      return nil unless block

      if options[:first]
        registered_first << block
      elsif options[:last]
        registered_last << block
      else
        registered << block
      end
    end

    def self.execute_collection(collection)
      collection.each_with_index do |b, idx|
        EasyExtensions.puts "Executing after install script no. #{idx + 1}/#{collection.size}..."

        b.call if b.respond_to?(:call)
      end
    end
  end
end
