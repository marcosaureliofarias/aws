module Easy
  module BasicEntity
    extend ActiveSupport::Concern

    included do

      class_attribute :_allowed_subclasses
      class_attribute :namespace
      class_attribute :parent_entity_symbol
      class_attribute :shallow

      def self.add_allowed_subclass(value)
        if value.is_a?(Array)
          value.each do |subclass|
            add_subclass(subclass)
          end
        else
          add_subclass(value)
        end
      end

      def self.allowed_subclasses=(value)
        add_allowed_subclass(value)
      end

      def self.allowed_subclasses
        self._allowed_subclasses || {}
      end

    end

    class_methods do

      def add_subclass(klass, condition = nil)
        self._allowed_subclasses             ||= {}
        self._allowed_subclasses[klass.to_s] = condition
      end

      def allowed_subclasses_for(user = nil)
        self.allowed_subclasses.keys.
            select { |klass| self.allowed_subclass?(klass, user) }.
            map { |klass| klass.safe_constantize }.reject(&:blank?)
      end

      def allowed_subclass?(klass, user = nil)
        return false unless self.allowed_subclasses.key?(klass.to_s)

        condition = self.allowed_subclasses[klass.to_s]

        if condition.is_a?(Proc)
          condition.call(user)
        elsif condition.nil?
          true
        else
          !!condition
        end
      end

      def belongs_to_parent(name, options = {})
        self.parent_entity_symbol = name
        belongs_to(name, options)
      end

      def parent_to_base(parent_entity = nil)
        parent_entity ? parent_entity.becomes(parent_entity.class.base_class) : nil
      end

      def to_route(parent_entity = nil)
        if parent_entity_symbol
          [parent_to_base(parent_entity), namespace, base_class]
        else
          [namespace, base_class]
        end
      end

      def parent_entity_id_symbol
        @parent_entity_id_symbol ||= (parent_entity_symbol.to_s + '_id').to_sym if parent_entity_symbol
      end

      def parent_entity_class
        @parent_entity_class ||= self.reflect_on_association(parent_entity_symbol).klass if parent_entity_symbol
      end

    end

    def to_route
      if self.class.shallow
        [namespace, becomes(self.class.base_class)]
      else
        [namespace, self.class.parent_to_base(parent_entity), becomes(self.class.base_class)]
      end
    end

    def parent_entity
      @parent_entity ||= send(parent_entity_symbol) if parent_entity_symbol
    end

    def parent_entity=(value)
      @parent_entity = nil
      send(parent_entity_symbol.to_s + '=', value) if parent_entity_symbol
    end

  end
end
