module EasyPatch
  module Acts
    module ActsAsEasyChecklist
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        def acts_as_easy_checklist(options={})
          return if self.included_modules.include?(EasyPatch::Acts::ActsAsEasyChecklist::ActsAsEasyChecklistMethods)

          send(:include, EasyPatch::Acts::ActsAsEasyChecklist::ActsAsEasyChecklistMethods)
        end

      end

      module ActsAsEasyChecklistMethods
        def self.included(base)
          base.class_eval do
            has_many :easy_checklists, :as => :entity, :dependent => :destroy
            safe_attributes 'easy_checklists', 'easy_checklists_attributes'
            accepts_nested_attributes_for :easy_checklists, :allow_destroy => true,
              :reject_if => proc { |attributes|
                attributes[:name].blank? && attributes[:easy_checklist_items_attributes] && attributes[:easy_checklist_items_attributes].all?{|_, item_attributes|
                  item_attributes['subject'].blank?
                }
              }

            def easy_checklist_templates
              return @easy_checklist_templates unless @easy_checklist_templates.nil?
              @easy_checklist_templates = self.project.easy_checklist_templates.to_a if self.project
              @easy_checklist_templates ||= []
            end

            def all_easy_checklist_items
              self.easy_checklists.collect do |easy_checklist|
                easy_checklist.easy_checklist_items
              end.flatten
            end

          end
        end
      end

    end
  end
end
