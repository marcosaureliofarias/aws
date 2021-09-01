module EasyTwofa
  class VerificationStatus

    attr_reader :errors

    def initialize
      @errors = []
    end

    def success?
      @errors.empty?
    end

  end
end
