class Object

  def nested_send(symbol, *args)
    obj        = nil
    symbols    = symbol.to_s.split('.').map { |s| s.to_sym }
    last_index = symbols.length - 1
    symbols.each_with_index do |nested_symbol, i|
      if i.zero?
        if respond_to?(nested_symbol)
          obj = (last_index == i) ? __send__(nested_symbol, *args) : __send__(nested_symbol)
        else
          obj = nil
          break
        end
      else
        if obj.respond_to?(nested_symbol)
          obj = (last_index == i) ? obj.__send__(nested_symbol, *args) : obj.__send__(nested_symbol)
        else
          obj = nil
          break
        end
      end
    end
    obj
  end

end

class NilClass
  def to_boolean
    false
  end
end

class FalseClass
  def to_boolean
    false
  end
end

class TrueClass
  def to_boolean
    true
  end
end
