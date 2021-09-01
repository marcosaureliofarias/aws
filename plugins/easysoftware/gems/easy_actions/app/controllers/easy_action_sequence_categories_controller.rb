class EasyActionSequenceCategoriesController < Easy::Redmine::BasicController

  menu_item :easy_action

  self.entity_class       = EasyActionSequenceCategory
  self.entity_query_class = EasyActionSequenceCategoryQuery

  before_action :authorize_global

  def autocomplete
    @entities    = EasyActionSequence.like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i).to_a
    @name_column = :name

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/entities_with_id', locals: { additional_select_options: [] }, formats: [:api] }
    end
  end

end
