class EasyQuotesEngine

  attr_reader :quote

  def initialize(*args)

  end

  def get_quote
    raise NotImplementedError
  end

  def author

  end

  def text

  end

  def to_s
    is_loaded? && @quote.to_s
  end

  def to_xml
    is_loaded? && @quote.to_xml
  end

  def to_json
    is_loaded? && @quote.to_json
  end

  private

  def is_loaded?
    !!@quote
  end
end
