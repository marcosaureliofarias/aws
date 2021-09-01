class EpmIframe < EasyPageModule

  def self.translatable_keys
    [
        %w[heading]
    ]
  end

  def category_name
    @category_name ||= 'others'
  end

end
