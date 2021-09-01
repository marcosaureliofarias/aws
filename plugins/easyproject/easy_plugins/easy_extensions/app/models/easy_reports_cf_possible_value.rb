class EasyReportsCfPossibleValue

  def initialize(value, id = nil)
    @value = value
    @id    = id || value
  end

  def id
    @id
  end

  def name
    @value
  end

  def to_s
    name
  end
end
