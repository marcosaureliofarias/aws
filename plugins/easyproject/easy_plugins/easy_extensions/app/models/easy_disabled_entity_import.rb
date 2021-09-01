class EasyDisabledEntityImport < EasyEntityImport
  class << self
    def disabled?
      true
    end
  end
end
