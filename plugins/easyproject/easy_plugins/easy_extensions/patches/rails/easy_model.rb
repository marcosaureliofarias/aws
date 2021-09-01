module EasyPatch
  module EasyModel

    def self.included(base)
      base.class_eval do

        class_attribute :associated_entity_class, :associated_query_class, :proc_field_mail_to

        def self.set_associated_entity_class(klass)
          self.associated_entity_class = klass
        end

        def self.set_associated_query_class(klass)
          self.associated_query_class = klass
        end

        def self.set_proc_field_mail_to(&block)
          self.proc_field_mail_to = block
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::EasyModel'
