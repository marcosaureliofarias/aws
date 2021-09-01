class EasyActionSequenceInstancesController < Easy::Redmine::BasicController

  menu_item :easy_action

  self.entity_class       = EasyActionSequenceInstance
  self.entity_query_class = EasyActionSequenceInstanceQuery

  before_action -> { find_entity }, only: %i[chart check_state]
  before_action :authorize_global

  def chart
  end

  def check_state
    EasyActionSequenceInstanceEngineJob.perform_now(@entity)

    redirect_to polymorphic_path(@entity.to_route)
  end

  #protected
  #
  #def entity_class_scope
  #  @parent_entity.instances
  #end

end
