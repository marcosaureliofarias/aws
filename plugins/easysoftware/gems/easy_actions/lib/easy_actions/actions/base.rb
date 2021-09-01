module EasyActions
  module Actions
    class Base
      include ActiveModel::Model

      def fire(entity)
      end

      def to_partial_path
        view_folder + '/' + view_name
      end

      def view_folder
        "easy_actions/actions"
      end

      def view_name
        self.class.name.demodulize.underscore + "_form"
      end

      def form_template_exists?(view_context)
        view_context.template_exists?(view_name, view_folder, true)
      end

      private

      def _assign_attribute(k, v)
        setter = :"#{k}="
        if respond_to?(setter)
          public_send(setter, v)
        else
          # Do nothing
        end
      end

    end
  end
end
