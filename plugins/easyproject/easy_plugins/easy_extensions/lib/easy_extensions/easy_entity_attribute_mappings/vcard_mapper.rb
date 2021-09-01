module EasyExtensions
  module EasyEntityAttributeMappings
    class VcardMapper < Mapper

      def initialize(from_instance, to_class, options = nil)
        super
        @entity_to = EasyExtensions::Export::EasyVcard.new(from_instance, options)
      end

    end
  end
end
