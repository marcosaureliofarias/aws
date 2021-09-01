module EasyButtons
  module HaveEasyButton

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module ClassMethods
      def have_easy_buttons(options = {})
        return if self.included_modules.include?(EasyButtons::HaveEasyButton::HaveEasyButtonMethods)

        EasyButton.register(self, options)

        send(:include, EasyButtons::HaveEasyButton::HaveEasyButtonMethods)
      end
    end

    module InstanceMethods
      def easy_buttons?
        respond_to(:easy_buttons)
      end
    end

    module HaveEasyButtonMethods

      def self.included(base)
        base.class_eval do

          def easy_buttons_logger(message)
            return unless Rails.env.development?

            if Rails.logger
              Rails.logger.info { message }
            else
              $stdout.puts message
              $stdout.flush
            end
          end

          # Return all active buttons
          def easy_buttons
            t = Time.now

            EasyButton.reload_buttons
            buttons = EasyButton.active_for(self)

            t = Time.now - t
            easy_buttons_logger("#{EasyButton.instances.size} buttons reloaded and executed in %.10fs" % t)

            buttons
          end

          def easy_button_edit_path
            EasyButton.registered_entities[self.class][:edit_path].call(self)
          end

          def easy_button_update_path
            EasyButton.registered_entities[self.class][:update_path].call(self)
          end

          # # Return button by id (even inactive)
          # def action_button(id)
          #   self.__easy_buttons.detect do |action_button|
          #     action_button.id == id
          #   end
          # end

        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyButtons::HaveEasyButton'
