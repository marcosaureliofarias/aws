module EasyExtensions
  module ActionProposer

    mattr_accessor :items
    self.items = []

    class << self

      def add(url, options = {})
        item                 = ActionProposerItem.new
        item.url             = url
        item.caption_key     = options[:caption_key] || :"easy_proposer.#{url[:controller]}.#{url[:action]}.caption"
        item.description_key = options[:description_key] || :"easy_proposer.#{url[:controller]}.#{url[:action]}.description"

        items << item
      end

      def to_json
        sorted_items.to_json
      end

      def sorted_items
        items.sort_by(&:caption)
      end

      def get_items(term = '', limit = nil)
        result = []
        sorted_items.each do |item|
          next if !item.caption.downcase.include?(term.downcase)
          next if !User.current.allowed_to?(item.url, nil, { global: true })
          result << item
          break if limit && result.size == limit
        end
        result
      end

    end
  end

  class ActionProposerItem
    include Redmine::I18n

    attr_accessor :caption_key, :url, :description_key

    def caption
      get_string(@caption_key)
    end

    def description
      get_string(@description_key)
    end

    def get_string(key)
      case key
      when Symbol
        l(key)
      when Proc
        key.call
      else
        key
      end
    end

    def as_json(options = nil)
      { 'value' => url, 'label' => caption }
    end

  end
end
