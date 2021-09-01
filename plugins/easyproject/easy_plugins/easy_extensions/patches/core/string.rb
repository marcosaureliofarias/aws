class String
  def to_boolean
    ['true', 1, '1', 'yes', 't', 'y'].include?(self.downcase)
  end

  def to_id
    underscore.tr('/', '_')
  end
end
