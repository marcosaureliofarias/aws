class EasyActionTransitionsController < Easy::Redmine::BasicController

  self.entity_class = EasyActionTransition

  before_action :authorize_global

  def autocomplete
    @entities    = entity_class_scope.like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i).to_a
    @name_column = :name

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/entities_with_id', locals: { additional_select_options: [] }, formats: [:api] }
    end
  end

  protected

  def entity_class_scope
    @parent_entity.transitions
  end

end
