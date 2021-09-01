module EasyGraphql
  module Mutations
    class EasyGanttResource < Base
      description 'Create / update EasyGanttResource.'

      argument :id, ID, required: false
      argument :attributes, GraphQL::Types::JSON, required: false

      field :easy_gantt_resource, Types::EasyGanttResource, null: true
      field :errors, [Types::Error], null: true

      def resolve(attributes:, id: nil)
        self.entity = prepare_easy_gantt_resource(id)
        return response_record_not_found unless entity

        entity.safe_attributes = attributes

        if entity.save
          if Redmine::Plugin.installed?(:easy_gantt_resources)
            issue = entity.issue
            if issue.allocable?
              #allocator = EasyGanttResources::IssueAllocator.get(issue)
              #allocator.recalculate!
            else
              issue.easy_gantt_resources.delete_all
            end
          end
          response_all
        else
          response_errors
        end
      end

      private

      def prepare_easy_gantt_resource(id)
        if id
          ::EasyGanttResource.find_by(id: id)
        else
          ::EasyGanttResource.new
        end
      end
    end
  end
end
