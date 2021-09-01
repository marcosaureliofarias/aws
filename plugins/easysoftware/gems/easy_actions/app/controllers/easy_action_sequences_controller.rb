class EasyActionSequencesController < Easy::Redmine::BasicController

  self.entity_class       = EasyActionSequence
  self.entity_query_class = EasyActionSequenceQuery

  before_action :authorize_global

  def autocomplete
    @entities    = EasyActionSequence.like(params[:term]).limit(EasySetting.value('easy_select_limit').to_i).to_a
    @name_column = :name

    respond_to do |format|
      format.api { render template: 'easy_auto_completes/entities_with_id', locals: { additional_select_options: [] }, formats: [:api] }
    end
  end

  def modal_index
    retrieve_query(EasyActionSequenceQuery)

    sort_init(@query.sort_criteria.presence || @query.default_sort_criteria.presence)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render(@query, {})

    respond_to do |format|
      format.js
      format.html
    end
  end

end
