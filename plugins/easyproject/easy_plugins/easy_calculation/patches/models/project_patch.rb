module EasyCalculations
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_one :easy_calculation
        has_many :easy_calculation_items

        safe_attributes 'calculation_date',
                        'calculation_discount',
                        'calculation_discount_is_percent',
                        'client_id',
                        'client_name'

        validates :calculation_discount, numericality: { only_integer: true, allow_nil: true, less_than: 2147483647 }

        private

        def copy_easy_calculation(project)
          if project.module_enabled?('easy_calculation') && project.easy_calculation
            new_easy_calculation = project.easy_calculation.dup
            new_easy_calculation.project_id = self.id
            new_easy_calculation.save
            project.easy_calculation_items.each do |calculation_item|
              new_calculation_item = calculation_item.dup
              new_calculation_item.project_id = self.id
              new_calculation_item.save
            end
          end
        end

      end
    end

    module InstanceMethods
      def calculation_discount=(x)
        if x.present?
          super(x.to_i.abs)
        else
          super(x)
        end
      end

      def solution_entities(settings = EasySetting.value(:calculation))
        settings ||= {}
        entities = issues.order(:calculation_position, :due_date).where(:tracker_id => settings[:tracker_ids])
        entities = entities.where(:in_easy_calculation => true) if !settings[:show_in_easy_calculation]
        entities = entities.limit(50)
        entities += easy_calculation_items
        return entities.sort_by{|e| [e.calculation_position || 0, (e.is_a?(Issue) ? e.due_date : nil) || Date.today]}
      end
    end

    module ClassMethods
    end

  end

  module ContactProjectPatch

    def self.included(base)
      base.class_eval do
        belongs_to :client, :class_name => 'EasyContact'
      end
    end
  end

  module EasyContactPatch

    def self.included(base)
      base.class_eval do
        has_many :calculation_projects, :class_name => 'Project', :foreign_key => 'client_id', :dependent => :nullify
      end
    end
  end


end

EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyCalculations::ProjectPatch'
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyCalculations::ContactProjectPatch', :if => Proc.new { Redmine::Plugin.installed?(:easy_contacts) }
EasyExtensions::PatchManager.register_model_patch 'EasyContact', 'EasyCalculations::EasyContactPatch', :if => Proc.new { Redmine::Plugin.installed?(:easy_contacts) }
